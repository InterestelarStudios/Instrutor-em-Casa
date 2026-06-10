const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();

// Configura a região global para southamerica-east1 (São Paulo) para melhor performance no Brasil
setGlobalOptions({ region: "southamerica-east1" });

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
        console.log(`Notificação salva no Firestore para ${userId}: ${title}`);

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
            console.log(`Push enviado para ${userId}`);
        } else {
            console.log(`Usuário ${userId} não possui fcmToken.`);
        }
    } catch (error) {
        console.error(`Erro ao notificar usuário ${userId}:`, error);
    }
}

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
