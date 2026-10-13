const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();

// Configura a região global para southamerica-east1 (São Paulo) para melhor performance no Brasil
setGlobalOptions({ region: "southamerica-east1" });

const { GoogleGenAI } = require("@google/genai");

// Chaves e configurações de backend seguras (obtidas via variáveis de ambiente / .env)
const ASAAS_API_KEY = process.env.ASAAS_API_KEY || "";
const ASAAS_BASE_URL = process.env.ASAAS_BASE_URL || "https://api.asaas.com/v3";
const INFOSIMPLES_TOKEN = process.env.INFOSIMPLES_TOKEN || "";
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || "";

/**
 * Função auxiliar para enviar notificação para um usuário e salvar no histórico.
 */
async function notifyUser(userId, title, description, route, contentId) {
    try {
        const userDoc = await admin.firestore().collection("users").doc(userId).get();
        if (!userDoc.exists) {
            console.log(`Usuário ${userId} não encontrado para notificação.`);
            return;
        }

        const fcmToken = userDoc.data().fcmToken;
        const notificationId = admin.firestore().collection("notifications").doc().id;

        const notification = {
            id: notificationId,
            title: title,
            description: description,
            created: admin.firestore.FieldValue.serverTimestamp(),
            route: route,
            contentId: contentId,
            read: false,
            visibleTo: [userId],
        };

        // Salva na coleção global de notificações
        await admin.firestore().collection("notifications").doc(notificationId).set(notification);

        // Incrementa o contador do usuário
        await admin.firestore().collection("users").doc(userId).update({
            "notificationsCount": admin.firestore.FieldValue.increment(1)
        });

        if (fcmToken) {
            const message = {
                notification: { title: title, body: description },
                data: { 
                    route: route || "", 
                    contentId: contentId || "",
                    click_action: "FLUTTER_NOTIFICATION_CLICK"
                },
                token: fcmToken,
            };
            await admin.messaging().send(message);
        }
    } catch (error) {
        console.error(`Erro ao notificar usuário ${userId}:`, error);
    }
}

/**
 * Webhook para receber notificações do Asaas (Pagamentos e Contas).
 */
exports.asaasWebhook = onRequest(async (req, res) => {
    const event = req.body;
    console.log(`Evento Asaas recebido: ${event.event}`);

    try {
        // --- TRATAMENTO DE PAGAMENTOS ---
        if (event.payment) {
            const payment = event.payment;
            const aulaId = payment.externalReference;

            if (!aulaId) {
                console.log("Evento de pagamento ignorado: externalReference (aulaId) não encontrado.");
                return res.status(200).send("Ignored");
            }

            const aulaDoc = await admin.firestore().collection("aulas").doc(aulaId).get();
            if (!aulaDoc.exists) {
                console.log(`Aula ${aulaId} não encontrada no Firestore.`);
                return res.status(200).send("Not Found");
            }

            const aula = aulaDoc.data();

            let aulaUpdate = {};
            let paymentStatus = payment.status;

            switch (event.event) {
                case "PAYMENT_RECEIVED":
                case "PAYMENT_CONFIRMED":
                    aulaUpdate.status = "accepted";
                    aulaUpdate.paymentStatus = "CONFIRMED";
                    await notifyUser(aula.aluno.id, "Pagamento Confirmado!", "Sua aula foi confirmada com sucesso.", "/aula_details", aulaId);
                    await notifyUser(aula.instrutor.id, "Novo Agendamento Pago!", `O aluno ${aula.aluno.name} confirmou o pagamento.`, "/aula_details", aulaId);
                    break;

                case "PAYMENT_REJECTED":
                case "PAYMENT_CHARGEBACK_REQUESTED":
                    aulaUpdate.status = "refused";
                    aulaUpdate.paymentStatus = "REJECTED";
                    await notifyUser(aula.aluno.id, "Problema no Pagamento", "Seu pagamento foi recusado. Verifique com seu banco.", "/aula_details", aulaId);
                    break;

                case "PAYMENT_OVERDUE":
                    aulaUpdate.paymentStatus = "OVERDUE";
                    await notifyUser(aula.aluno.id, "Pagamento Atrasado", "A fatura da sua aula venceu. Gere uma nova para continuar.", "/aula_details", aulaId);
                    break;

                case "PAYMENT_REFUNDED":
                    aulaUpdate.status = "canceled";
                    aulaUpdate.paymentStatus = "REFUNDED";
                    break;
            }

            if (Object.keys(aulaUpdate).length > 0) {
                await admin.firestore().collection("aulas").doc(aulaId).update(aulaUpdate);
            }

            // Sync with cobrancas collection
            await admin.firestore().collection("cobrancas").doc(payment.id).set({
                status: paymentStatus
            }, { merge: true });
        }


        return res.status(200).send("OK");
    } catch (error) {
        console.error("Erro ao processar webhook Asaas:", error);
        return res.status(500).send("Internal Server Error");
    }
});

/**
 * Monitora sessões perdidas e aplica a regra dos 30%.
 */
exports.checkMissedSessions = onSchedule("every 1 hours", async (event) => {
    const now = admin.firestore.Timestamp.now();
    const aulasSnapshot = await admin.firestore().collection("aulas")
        .where("status", "in", ["accepted", "active"])
        .get();

    for (const doc of aulasSnapshot.docs) {
        const aula = doc.data();
        let changed = false;
        let missedCount = 0;
        const totalSessions = aula.sessions.length;

        const updatedSessions = aula.sessions.map(session => {
            if (session.status === "scheduled" && session.date.toMillis() < now.toMillis() && !session.end) {
                session.status = "missed";
                changed = true;
            }
            if (session.status === "missed") missedCount++;
            return session;
        });

        if (changed) {
            const missedRatio = missedCount / totalSessions;
            let newStatus = aula.status;

            if (missedRatio >= 0.3) {
                newStatus = "inactive";
                await notifyUser(aula.aluno.id, "Pacote Desativado", "Seu pacote de aulas foi cancelado por excesso de faltas.", "/aula_details", doc.id);
                await notifyUser(aula.instrutor.id, "Pacote Desativado", "Um pacote de aulas foi cancelado por excesso de faltas do aluno.", "/aula_details", doc.id);
            } else {
                await notifyUser(aula.aluno.id, "Sessão Perdida", "Você perdeu o horário de uma aula. Entre em contato para remarcar.", "/aula_details", doc.id);
            }

            await admin.firestore().collection("aulas").doc(doc.id).update({
                sessions: updatedSessions,
                status: newStatus
            });
        }
    }
});

/**
 * Envia lembretes de aula.
 */
exports.sendLessonReminders = onSchedule("0 8,18 * * *", async (event) => {
    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59);
    
    const tomorrowStart = new Date(startOfDay);
    tomorrowStart.setDate(tomorrowStart.getDate() + 1);
    const tomorrowEnd = new Date(endOfDay);
    tomorrowEnd.setDate(tomorrowEnd.getDate() + 1);

    const aulasSnapshot = await admin.firestore().collection("aulas")
        .where("status", "in", ["accepted", "active"])
        .get();

    for (const doc of aulasSnapshot.docs) {
        const aula = doc.data();
        for (const session of aula.sessions) {
            const sessionDate = session.date.toDate();
            
            if (now.getHours() === 8 && sessionDate >= startOfDay && sessionDate <= endOfDay && session.status === "scheduled") {
                await notifyUser(aula.aluno.id, "Aula Hoje!", `Lembrete: Você tem aula hoje às ${sessionDate.getHours()}:${sessionDate.getMinutes().toString().padStart(2, '0')}.`, "/aula_details", doc.id);
                await notifyUser(aula.instrutor.id, "Aula Hoje!", `Lembrete: Você tem aula hoje com ${aula.aluno.name} às ${sessionDate.getHours()}:${sessionDate.getMinutes().toString().padStart(2, '0')}.`, "/aula_details", doc.id);
            }

            if (now.getHours() === 18 && sessionDate >= tomorrowStart && sessionDate <= tomorrowEnd && session.status === "scheduled") {
                await notifyUser(aula.aluno.id, "Aula Amanhã!", `Lembrete: Você tem aula amanhã às ${sessionDate.getHours()}:${sessionDate.getMinutes().toString().padStart(2, '0')}.`, "/aula_details", doc.id);
                await notifyUser(aula.instrutor.id, "Aula Amanhã!", `Lembrete: Você tem aula amanhã com ${aula.aluno.name} às ${sessionDate.getHours()}:${sessionDate.getMinutes().toString().padStart(2, '0')}.`, "/aula_details", doc.id);
            }
        }
    }
});

/**
 * Notifica quando uma aula é solicitada.
 */
exports.onLessonRequested = onDocumentCreated("aulas/{aulaId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    try {
        const aula = snapshot.data();
        await notifyUser(
            aula.instrutor.id, 
            "Nova Solicitação de Aula", 
            `Você recebeu uma proposta para a categoria ${aula.category}.`, 
            "/aula_details", 
            event.params.aulaId
        );
    } catch (error) {
        console.error("Erro na função onLessonRequested:", error);
    }
});

/**
 * Notifica mudanças gerais na aula (status, trajeto).
 */
exports.onLessonUpdated = onDocumentUpdated("aulas/{aulaId}", async (event) => {
    const newData = event.data.after.data();
    const oldData = event.data.before.data();

    // 1. Mudança de Status Global
    if (newData.status !== oldData.status) {
        if (newData.status === "accepted") {
            await notifyUser(newData.aluno.id, "Aula Aceita!", "O instrutor aceitou sua solicitação. Prepare-se!", "/aula_details", event.params.aulaId);
        } else if (newData.status === "refused") {
            await notifyUser(newData.aluno.id, "Aula Recusada", "O instrutor não pôde aceitar sua aula no momento.", "/aula_details", event.params.aulaId);
        } else if (newData.status === "canceled") {
            const canceledBy = newData.canceledBy;
            const targetId = canceledBy === newData.aluno.id ? newData.instrutor.id : newData.aluno.id;
            const targetName = canceledBy === newData.aluno.id ? "O aluno" : "O instrutor";
            await notifyUser(targetId, "Aula Cancelada", `${targetName} cancelou o agendamento.`, "/aula_details", event.params.aulaId);
        }
    }

    // 2. Mudança de Trajeto (Journey State) nas sessões
    const newSessions = newData.sessions || [];
    const oldSessions = oldData.sessions || [];

    for (let i = 0; i < newSessions.length; i++) {
        const newS = newSessions[i];
        const oldS = oldSessions[i];

        if (oldS && newS.journeyState !== oldS.journeyState) {
            if (newS.journeyState === "enRoute") {
                await notifyUser(newData.aluno.id, "Instrutor a caminho", "O instrutor iniciou o trajeto até você. Acompanhe no mapa!", "/aula_details", event.params.aulaId);
            } else if (newS.journeyState === "arrived") {
                await notifyUser(newData.aluno.id, "Instrutor chegou", "O instrutor chegou ao local de encontro!", "/aula_details", event.params.aulaId);
            }
        }
    }
});

/**
 * Notifica quando uma nova mensagem é enviada no chat.
 */
exports.onMessageCreated = onDocumentCreated("messages/{messageId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    try {
        const message = snapshot.data();
        const chatId = message.chatId;
        const senderId = message.user.id;

        const chatDoc = await admin.firestore().collection("chats").doc(chatId).get();
        if (!chatDoc.exists) return;

        const chatData = chatDoc.data();
        const recipientId = chatData.usersId.find(id => id !== senderId);

        if (!recipientId) return;

        await notifyUser(
            recipientId, 
            `Nova mensagem de ${message.user.name}`, 
            message.message.length > 50 ? message.message.substring(0, 47) + "..." : message.message, 
            "/chat", 
            chatId
        );
    } catch (error) {
        console.error("Erro na função onMessageCreated:", error);
    }
});

/**
 * Atualiza a média de estrelas do instrutor.
 */
exports.updateAverageRating = onDocumentCreated("ratings/{ratingId}", async (event) => {
    const rating = event.data.data();
    const toUserId = rating.toUserId;

    try {
        const ratingsSnapshot = await admin.firestore().collection("ratings")
            .where("toUserId", "==", toUserId)
            .get();

        if (ratingsSnapshot.empty) return;

        let totalStars = 0;
        ratingsSnapshot.forEach(doc => {
            totalStars += doc.data().stars;
        });

        const average = totalStars / ratingsSnapshot.size;

        const userDoc = await admin.firestore().collection("users").doc(toUserId).get();
        if (userDoc.exists && userDoc.data().type === "instrutor") {
            await admin.firestore().collection("users").doc(toUserId).update({
                "instrutor.rating": average,
                "instrutor.ratingCount": ratingsSnapshot.size
            });
        }
    } catch (error) {
        console.error("Erro na função updateAverageRating:", error);
    }
});

/**
 * Criação e Cobrança de Pagamentos no Asaas de forma segura no Backend.
 */
exports.createPaymentSession = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Usuário não autenticado.");
    }
    const uid = request.auth.uid;
    const { aulaData, billingType } = request.data || {};

    if (!aulaData || !billingType) {
        throw new HttpsError("invalid-argument", "Dados da aula ou tipo de cobrança não fornecidos.");
    }

    if (aulaData.aluno && aulaData.aluno.id && aulaData.aluno.id !== uid) {
        throw new HttpsError("permission-denied", "Operação não autorizada para este aluno.");
    }

    // 1. Obter dados do usuário no Firestore
    const userDoc = await admin.firestore().collection("users").doc(uid).get();
    if (!userDoc.exists) {
        throw new HttpsError("not-found", "Perfil de usuário não encontrado.");
    }
    const userData = userDoc.data();
    let asaasCustomerId = userData.asaasId;

    // 2. Se não possuir asaasId, criar cliente no Asaas
    if (!asaasCustomerId) {
        const cleanCpf = (userData.data?.cpf || "").replace(/\D/g, "");
        const cleanCep = (userData.data?.postalCode || "").replace(/\D/g, "");

        const custRes = await fetch(`${ASAAS_BASE_URL}/customers`, {
            method: "POST",
            headers: {
                "access_token": ASAAS_API_KEY,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                name: userData.name,
                email: userData.email,
                cpfCnpj: cleanCpf,
                postalCode: cleanCep
            })
        });

        const custJson = await custRes.json();
        if (!custRes.ok) {
            const msg = custJson.errors?.[0]?.description || "Erro ao registrar perfil no Asaas.";
            throw new HttpsError("internal", msg);
        }
        asaasCustomerId = custJson.id;
        await admin.firestore().collection("users").doc(uid).update({ asaasId: asaasCustomerId });
    }

    // 3. Criar Pagamento no Asaas
    const dueDate = new Date();
    dueDate.setDate(dueDate.getDate() + 1);
    const dueDateStr = dueDate.toISOString().split("T")[0];

    const paymentRes = await fetch(`${ASAAS_BASE_URL}/payments`, {
        method: "POST",
        headers: {
            "access_token": ASAAS_API_KEY,
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            customer: asaasCustomerId,
            billingType: billingType, // 'PIX', 'CREDIT_CARD', 'UNDEFINED'
            value: aulaData.price?.amount || 0,
            dueDate: dueDateStr,
            description: `Treinamento de Direção - ${aulaData.category || "Aula"}`,
            externalReference: aulaData.id
        })
    });

    const paymentJson = await paymentRes.json();
    if (!paymentRes.ok) {
        const msg = paymentJson.errors?.[0]?.description || "Erro ao gerar cobrança no Asaas.";
        throw new HttpsError("internal", msg);
    }

    const paymentId = paymentJson.id;
    const invoiceUrl = paymentJson.invoiceUrl;
    const paymentStatus = paymentJson.status || "PENDING";
    let pixQrCode = null;
    let pixPayload = null;
    let expirationDate = null;

    // 4. Se for PIX, buscar dados reais do PIX (QR Code e Copia e Cola)
    if (billingType === "PIX") {
        try {
            const pixRes = await fetch(`${ASAAS_BASE_URL}/payments/${paymentId}/pixQrCode`, {
                headers: { "access_token": ASAAS_API_KEY }
            });
            if (pixRes.ok) {
                const pixData = await pixRes.json();
                pixQrCode = pixData.encodedImage; // Base64 image
                pixPayload = pixData.payload;     // Copia e Cola EMV code
                expirationDate = pixData.expirationDate;
            }
        } catch (e) {
            console.error("Erro ao obter Pix QR Code:", e);
        }
    }

    // 5. Salvar na coleção cobrancas
    await admin.firestore().collection("cobrancas").doc(paymentId).set({
        id: paymentId,
        aulaId: aulaData.id,
        alunoId: uid,
        alunoName: userData.name,
        value: paymentJson.value || aulaData.price?.amount,
        billingType: billingType === "UNDEFINED" ? "DEBIT_CARD" : billingType,
        status: paymentStatus,
        invoiceUrl: invoiceUrl,
        dueDate: paymentJson.dueDate,
        created: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    return {
        paymentId: paymentId,
        invoiceUrl: invoiceUrl,
        paymentStatus: paymentStatus,
        pixQrCode: pixQrCode,
        pixPayload: pixPayload,
        expirationDate: expirationDate
    };
});

/**
 * Executa a transferência PIX de repasse ao instrutor via API Asaas.
 */
exports.executeInstructorPayout = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Usuário não autenticado.");
    }

    const { aulaId } = request.data || {};
    if (!aulaId) {
        throw new HttpsError("invalid-argument", "ID da aula não fornecido.");
    }

    // 1. Buscar a aula no Firestore
    const aulaRef = admin.firestore().collection("aulas").doc(aulaId);
    const aulaDoc = await aulaRef.get();
    if (!aulaDoc.exists) {
        throw new HttpsError("not-found", "Aula não encontrada.");
    }

    const aula = aulaDoc.data();

    // 2. Verificar se está disponível para transferência
    if (aula.transferStatus === "transferido") {
        throw new HttpsError("failed-precondition", "O repasse desta aula já foi realizado.");
    }

    if (aula.transferStatus !== "disponivel" && aula.status !== "done") {
        throw new HttpsError("failed-precondition", "A aula ainda não foi finalizada ou não está disponível para repasse.");
    }

    // 3. Buscar dados do instrutor para obter chave PIX
    const instrutorId = aula.instrutor.id;
    const instrutorDoc = await admin.firestore().collection("users").doc(instrutorId).get();
    if (!instrutorDoc.exists) {
        throw new HttpsError("not-found", "Cadastro do instrutor não encontrado.");
    }

    const instrutorData = instrutorDoc.data();
    const pixKey = instrutorData.instrutor?.pixKey;
    const pixKeyType = instrutorData.instrutor?.pixKeyType || "CPF";

    if (!pixKey) {
        throw new HttpsError("failed-precondition", "O instrutor não cadastrou uma chave PIX para recebimento.");
    }

    // 4. Buscar comissão da plataforma em configuracoes/precos
    let comissaoPercent = 20.0;
    try {
        const configDoc = await admin.firestore().collection("configuracoes").doc("precos").get();
        if (configDoc.exists && configDoc.data()?.taxa_comissao != null) {
            comissaoPercent = Number(configDoc.data().taxa_comissao) || 20.0;
        }
    } catch (err) {
        console.warn("Erro ao buscar configuracoes de comissao:", err);
    }

    const valorTotal = Number(aula.price?.amount) || 0;
    if (valorTotal <= 0) {
        throw new HttpsError("failed-precondition", "Valor da aula inválido para transferência.");
    }

    // Valor líquido para o instrutor (descontada a comissão da plataforma)
    const valorRepasse = Number((valorTotal * (1 - (comissaoPercent / 100))).toFixed(2));

    // Mapeia pixKeyType para o padrão Asaas
    let asaasPixType = "CPF";
    const typeUpper = (pixKeyType || "").toUpperCase();
    if (typeUpper.includes("EMAIL")) asaasPixType = "EMAIL";
    else if (typeUpper.includes("PHONE") || typeUpper.includes("TEL") || typeUpper.includes("CEL")) asaasPixType = "PHONE";
    else if (typeUpper.includes("EVP") || typeUpper.includes("ALEAT")) asaasPixType = "EVP";
    else if (typeUpper.includes("CNPJ")) asaasPixType = "CNPJ";
    else asaasPixType = "CPF";

    let cleanPixKey = pixKey;
    if (asaasPixType === "CPF" || asaasPixType === "CNPJ" || asaasPixType === "PHONE") {
        cleanPixKey = pixKey.replace(/\D/g, "");
    }

    // 5. Executar transferência PIX no Asaas
    let transferId = `TR_${Date.now()}`;
    let transferStatus = "DONE";

    try {
        const transferRes = await fetch(`${ASAAS_BASE_URL}/transfers`, {
            method: "POST",
            headers: {
                "access_token": ASAAS_API_KEY,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                value: valorRepasse,
                operationType: "PIX",
                pixAddressKey: cleanPixKey,
                pixAddressKeyType: asaasPixType,
                description: `Repasse Instrutor em Casa - Aula ${aulaId.substring(0, 8)}`
            })
        });

        const transferJson = await transferRes.json();
        if (!transferRes.ok) {
            const errorMsg = transferJson.errors?.[0]?.description || "Erro ao realizar transferência PIX no Asaas.";
            console.error("Erro Asaas Transfer:", transferJson);
            throw new HttpsError("internal", errorMsg);
        }

        transferId = transferJson.id || transferId;
        transferStatus = transferJson.status || "DONE";
    } catch (e) {
        if (e instanceof HttpsError) throw e;
        console.error("Exceção ao chamar /transfers:", e);
        throw new HttpsError("internal", `Falha na comunicação com o Asaas: ${e.message || e}`);
    }

    // 6. Atualizar Aula
    await aulaRef.update({
        transferStatus: "transferido",
        transferId: transferId,
        transferredAt: admin.firestore.FieldValue.serverTimestamp(),
        transferAmount: valorRepasse
    });

    // 7. Criar registro na coleção transferencias
    const newTransferDoc = admin.firestore().collection("transferencias").doc(transferId);
    await newTransferDoc.set({
        id: transferId,
        aulaId: aulaId,
        instrutorId: instrutorId,
        instrutorName: aula.instrutor.name,
        amount: valorRepasse,
        totalLessonAmount: valorTotal,
        date: admin.firestore.FieldValue.serverTimestamp(),
        pixKey: pixKey,
        pixKeyType: pixKeyType,
        status: transferStatus
    });

    // 8. Atualizar coleção ganhos/{instrutorId}/meses/{YYYY_MM}
    const now = new Date();
    const monthYear = `${now.getFullYear()}_${String(now.getMonth() + 1).padStart(2, "0")}`;
    const ganhosMesRef = admin.firestore()
        .collection("ganhos")
        .doc(instrutorId)
        .collection("meses")
        .doc(monthYear);

    await ganhosMesRef.set({
        total: admin.firestore.FieldValue.increment(valorRepasse),
        aulasCount: admin.firestore.FieldValue.increment(1),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    // 9. Notificar Instrutor
    await notifyUser(
        instrutorId,
        "Repasse Realizado!",
        `O repasse de R$ ${valorRepasse.toFixed(2).replace(".", ",")} foi enviado para sua chave PIX.`,
        "/aula_details",
        aulaId
    );

    return {
        success: true,
        transferId: transferId,
        amount: valorRepasse
    };
});

/**
 * Consulta de Veículos Segura via Cloud Functions
 */
exports.consultVehicleData = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Usuário não autenticado.");
    }

    const { plate, renavam, uf } = request.data || {};
    const cleanPlate = (plate || "").replace(/[^A-Za-z0-9]/g, "").toUpperCase();
    const cleanRenavam = (renavam || "").replace(/\D/g, "");
    const cleanUf = (uf || "am").trim().toLowerCase();

    if (!cleanPlate || !cleanRenavam) {
        throw new HttpsError("invalid-argument", "Placa e Renavam são obrigatórios.");
    }

    if (!INFOSIMPLES_TOKEN) {
        throw new HttpsError("failed-precondition", "Token da Infosimples não configurado nas variáveis de ambiente.");
    }

    try {
        const params = new URLSearchParams();
        params.append("token", INFOSIMPLES_TOKEN);
        params.append("placa", cleanPlate);
        params.append("renavam", cleanRenavam);

        // URL da API Estadual do DETRAN (v2)
        const url = `https://api.infosimples.com/api/v2/consultas/detran/${cleanUf}/veiculo`;

        const response = await fetch(url, {
            method: "POST",
            headers: {
                "Content-Type": "application/x-www-form-urlencoded"
            },
            body: params.toString(),
            signal: AbortSignal.timeout(25000)
        });

        const decoded = await response.json();

        if (decoded.code === 200 && Array.isArray(decoded.data) && decoded.data.length > 0) {
            const data = decoded.data[0];

            let brand = "";
            let model = "";

            // O DETRAN-AM e vários outros retornam 'marca' como 'FABRICANTE/MODELO' (ex: 'I/LR R.R SPT 3.0', 'FIAT/MOBI LIKE')
            const rawMarca = data.marca || data.marca_modelo || "";
            if (rawMarca.includes("/")) {
                const parts = rawMarca.split("/");
                brand = parts[0].trim();
                model = parts.slice(1).join("/").trim();
            } else if (rawMarca) {
                brand = rawMarca.trim();
                model = data.modelo || rawMarca.trim();
            }

            // Tratamento do ano: DETRAN-AM retorna "2019 / 2019" ou campos separados
            let yearFab = new Date().getFullYear();
            let yearMod = yearFab;

            if (data.ano_modelo && typeof data.ano_modelo === "string" && data.ano_modelo.includes("/")) {
                const yearParts = data.ano_modelo.split("/");
                yearFab = parseInt(yearParts[0].trim()) || yearFab;
                yearMod = parseInt(yearParts[1].trim()) || yearFab;
            } else {
                yearFab = parseInt(data.ano_fabricacao) || parseInt(data.ano_modelo) || yearFab;
                yearMod = parseInt(data.ano_modelo) || yearFab;
            }

            const color = data.cor || data.cor_veiculo || "Não informada";
            const fuel = data.combustivel || data.tipo_combustivel || "Flex";
            const chassis = data.chassi || data.numero_chassi || "";
            const category = data.categoria || data.tipo_categoria || "Particular";

            return {
                id: "",
                plate: cleanPlate,
                renavam: cleanRenavam,
                brand: brand || "Desconhecido",
                model: model || "Veículo",
                yearFabrication: yearFab,
                yearModel: yearMod,
                color: color,
                fuel: fuel,
                chassis: chassis,
                category: category
            };
        }

        // Se a API retornou erro específico da Infosimples
        const errorDetails = (decoded.errors && decoded.errors.length > 0)
            ? decoded.errors.join("; ")
            : (decoded.code_message || "Não foi possível consultar os dados do veículo no Detran.");

        console.error("Infosimples Detran error response:", decoded.code, errorDetails);

        if (decoded.code === 603) {
            throw new HttpsError("permission-denied", `Infosimples: ${errorDetails}`);
        } else if (decoded.code === 607 || decoded.code === 600 || decoded.code === 601) {
            throw new HttpsError("invalid-argument", `Dados inválidos: ${errorDetails}`);
        } else if (decoded.code === 602) {
            throw new HttpsError("unimplemented", `A consulta automática para a UF (${cleanUf.toUpperCase()}) não está disponível diretamente no Detran.`);
        } else {
            throw new HttpsError("not-found", errorDetails);
        }
    } catch (err) {
        if (err instanceof HttpsError) {
            throw err;
        }
        console.error("Error communicating with Infosimples Detran API:", err);
        throw new HttpsError("unavailable", `Erro na consulta veicular: ${err.message || err}`);
    }
});

/**
 * Extração Inteligente de Dados de Documentos Veiculares (CRLV / LADV) com Gemini AI
 */
exports.extractVehicleDocumentData = onCall({ timeoutSeconds: 60, memory: "512MiB" }, async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Usuário não autenticado.");
    }

    const { base64File, mimeType } = request.data || {};
    if (!base64File) {
        throw new HttpsError("invalid-argument", "Nenhum arquivo enviado para extração.");
    }

    const allowedMimes = ["image/jpeg", "image/png", "image/webp", "image/jpg", "application/pdf"];
    const effectiveMime = (mimeType || "image/jpeg").toLowerCase();
    if (!allowedMimes.includes(effectiveMime)) {
        throw new HttpsError("invalid-argument", `Tipo de arquivo não suportado: ${effectiveMime}. Envie JPG, PNG ou PDF.`);
    }

    try {
        let ai;
        if (GEMINI_API_KEY) {
            ai = new GoogleGenAI({ apiKey: GEMINI_API_KEY });
        } else {
            // Tenta inicializar com credenciais padrão do ambiente Google Cloud / Vertex AI
            try {
                ai = new GoogleGenAI({ vertexAI: true, project: "instrutor-em-casa", location: "southamerica-east1" });
            } catch (initErr) {
                console.warn("Vertex AI init warning:", initErr);
                ai = new GoogleGenAI({});
            }
        }

        const prompt = `Você é um assistente especialista em leitura e extração de dados de documentos veiculares brasileiros (como CRLV, CRLV-e digital do SENATRAN/DETRAN, LADV - Licença para Aprendizagem de Direção Veicular, ou comprovante de registro de veículo).

Analise o documento fornecido (imagem ou PDF) e extraia com máxima precisão os dados cadastrais do veículo no seguinte formato JSON:
{
  "plate": "Placa do veículo em letras maiúsculas sem traços (ex: ABC1D23 ou ABC1234)",
  "renavam": "Número do RENAVAM apenas dígitos (ex: 12345678901)",
  "brand": "Nome da marca/fabricante do veículo (ex: FIAT, CHEVROLET, VOLKSWAGEN, TOYOTA, HYUNDAI, RENAULT, HONDA)",
  "model": "Nome do modelo do veículo (ex: MOBI LIKE, ONIX PLUS, HB20, KWID, GOL, ARGO)",
  "yearFabrication": 2022,
  "yearModel": 2023,
  "color": "Cor predominante do veículo (ex: BRANCA, PRATA, PRETA, CINZA, VERMELHA)",
  "fuel": "Tipo de combustível (ex: FLEX, ALCOOL/GASOLINA, GASOLINA, DIESEL, ELETRICO)",
  "chassis": "Número do chassi do veículo (geralmente 17 caracteres alfanuméricos)",
  "category": "Categoria do veículo (ex: APRENDIZAGEM, PARTICULAR, ALUGUEL)"
}

Regras:
1. Se a marca e o modelo estiverem juntos como 'MARCA/MODELO' (ex: 'FIAT/MOBI LIKE 1.0'), separe a marca ('FIAT') do modelo ('MOBI LIKE 1.0').
2. Retorne apenas o objeto JSON válido, sem texto explicativo adicional.
3. Se algum campo específico não for encontrado com certeza, preencha com string vazia "" ou ano atual para números.`;

        const response = await ai.models.generateContent({
            model: "gemini-2.5-flash",
            contents: [
                {
                    role: "user",
                    parts: [
                        {
                            inlineData: {
                                mimeType: effectiveMime,
                                data: base64File
                            }
                        },
                        {
                            text: prompt
                        }
                    ]
                }
            ],
            config: {
                responseMimeType: "application/json"
            }
        });

        const rawText = response.text || "";
        console.log("Gemini document extraction raw response:", rawText);

        let parsedData = {};
        try {
            parsedData = JSON.parse(rawText);
        } catch (e) {
            const jsonMatch = rawText.match(/\{[\s\S]*\}/);
            if (jsonMatch) {
                parsedData = JSON.parse(jsonMatch[0]);
            } else {
                throw new Error("Não foi possível decodificar os dados retornados pelo modelo.");
            }
        }

        const currentYear = new Date().getFullYear();
        return {
            plate: (parsedData.plate || "").replace(/[^A-Za-z0-9]/g, "").toUpperCase(),
            renavam: (parsedData.renavam || "").replace(/\D/g, ""),
            brand: (parsedData.brand || "").trim().toUpperCase(),
            model: (parsedData.model || "").trim().toUpperCase(),
            yearFabrication: parseInt(parsedData.yearFabrication) || currentYear,
            yearModel: parseInt(parsedData.yearModel) || currentYear,
            color: (parsedData.color || "").trim().toUpperCase() || "NÃO INFORMADA",
            fuel: (parsedData.fuel || "").trim().toUpperCase() || "FLEX",
            chassis: (parsedData.chassis || "").trim().toUpperCase(),
            category: (parsedData.category || "").trim().toUpperCase() || "APRENDIZAGEM"
        };
    } catch (err) {
        console.error("Erro na extração de documento com Gemini:", err);
        throw new HttpsError("internal", `Não foi possível extrair os dados do documento: ${err.message || err}`);
    }
});


