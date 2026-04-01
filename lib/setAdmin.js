const admin = require("firebase-admin");

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const uid = k7ngxrpHIWSFdFa3pX8qRxw6bgA3;

admin.auth().setCustomUserClaims(uid, { admin: true })
  .then(() => {
    console.log("Admin claim set successfully.");
    process.exit(0);
  });