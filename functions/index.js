const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const NOTIFICATION_TITLE = "⏰ เตรียมเข้าเรียน!";
const NOTIFICATION_BODY = (slot) =>
  `${slot.title || "ไม่ระบุ"} เริ่มเวลา ${slot.startTime.hour}:${String(
    slot.startTime.minute
  ).padStart(2, "0")} - ${slot.endTime.hour}:${String(slot.endTime.minute).padStart(
    2,
    "0"
  )} ที่ ${slot.location} โดย ${slot.professor}`;
const SCHEDULE_DATA_TYPE = "schedule";

exports.notifyCurrentTimetable = functions.pubsub
  .schedule("* * * * *")
  .timeZone("Asia/Bangkok")
  .onRun(async (context) => {
    const { DateTime } = require("luxon");

    const now = DateTime.now().setZone("Asia/Bangkok");
    const currentDay = (now.weekday + 6) % 7;
    const currentMinutes = now.hour * 60 + now.minute;

    console.log("🔍 ฟังก์ชัน notifyCurrentTimetable ถูกเรียกแล้ว");
    console.log(`⏰ กำลังตรวจสอบเวลา: วันที่ ${currentDay}, นาทีที่ ${currentMinutes}`);

    const usersSnapshot = await admin.firestore().collection("Users").get();
    console.log(`👤 พบผู้ใช้ทั้งหมด: ${usersSnapshot.size}`);

    const userProcessingPromises = usersSnapshot.docs.map(async (userDoc) => {
      const email = userDoc.id;
      const userData = userDoc.data();
      const timetableId = userData.currentTimetableID;

      console.log(`➡️ ${email} | currentTimetableId: ${timetableId}`);

      if (!timetableId) {
        console.log(`⚠️ ${email} ไม่มี currentTimetableId`);
        return;
      }

      const timetableDoc = await admin.firestore()
        .collection("Users")
        .doc(email)
        .collection("Timetables")
        .doc(timetableId)
        .get();

      console.log(
        `📄 ดึง Timetable สำเร็จสำหรับ ${email}: exists=${timetableDoc.exists}`
      );

      if (!timetableDoc.exists) {
        console.log(`⚠️ ${email} ไม่มี Timetable ID: ${timetableId}`);
        return;
      }

      const { days = {} } = timetableDoc.data();
      const todaySlots = days[String(currentDay)] || [];
      console.log(`📆 ${email} | คาบวันนี้ (${currentDay}): ${todaySlots.length} คาบ`);

      const slotsToNotify = todaySlots.filter((slot) => {
        if (slot.isNotify === false) {
          return false;
        }
        if (
          !slot.startTime ||
          typeof slot.startTime.hour !== "number" ||
          typeof slot.startTime.minute !== "number"
        ) {
          console.log(`⚠️ startTime ผิด format สำหรับ ${email}:`, slot.startTime);
          return false;
        }

        const startTimeMinutes = slot.startTime.hour * 60 + slot.startTime.minute;
        const notifyBeforeMinutes = (slot.notifyTime?.hour || 0) * 60 + (slot.notifyTime?.minute || 0);
        const notifyAtMinutes = startTimeMinutes - notifyBeforeMinutes;

        return notifyAtMinutes === currentMinutes;
      });

      console.log(`🔔 ${email} | คาบที่ต้องแจ้งเตือน: ${slotsToNotify.length} คาบ`);

      if (slotsToNotify.length > 0) {
        const tokenSnap = await admin.firestore()
          .collection("Users")
          .doc(email)
          .collection("Tokens")
          .get();

          const tokens = tokenSnap.docs.map((doc) => doc.id);
          if (tokens.length === 0) {
            console.log(`📭 ${email} ไม่มี token`);
            return;
          }
  
          const multicastMessage = {
            tokens: tokens,
            notification: {
              title: NOTIFICATION_TITLE,
              body: NOTIFICATION_BODY(slotsToNotify[0]),
            },
            data: {
              type: SCHEDULE_DATA_TYPE,
              timetableId: timetableId,
            },
          };
  
          try {
            const response = await admin.messaging().sendEachForMulticast(multicastMessage);
            response.responses.forEach((resp, idx) => {
              if (resp.success) {
                console.log(`✅ ส่งแจ้งเตือนสำเร็จไปยัง ${tokens[idx]}`);
              } else {
                console.error(`❌ ส่งไม่สำเร็จไปยัง ${tokens[idx]} | ${resp.error}`);
              }
            });
          } catch (error) {
            console.error(`🚨 เกิดข้อผิดพลาดในการส่งแจ้งเตือน:`, error);
          }
      }
    });

    await Promise.all(userProcessingPromises);

    return null;
  });