const functions = require("firebase-functions");
const admin = require("firebase-admin");

function getDb() {
  if (!admin.apps.length) {
    admin.initializeApp();
  }
  return admin.firestore();
}

function getAuth() {
  if (!admin.apps.length) {
    admin.initializeApp();
  }
  return admin.auth();
}

function generateTemporaryPassword() {
  const chars =
    "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%";
  let password = "";
  for (let i = 0; i < 16; i += 1) {
    password += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return password;
}

async function callerIsAdmin(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Authentication required."
    );
  }

  if (context.auth.token.admin === true) {
    return true;
  }

  const userDoc = await getDb().collection("users").doc(context.auth.uid).get();
  if (!userDoc.exists) {
    return false;
  }

  const permissions = userDoc.data().permissions || [];
  return permissions.includes("admin") || permissions.includes("*");
}

async function resolvePermissionsForRole(roleId) {
  if (!roleId) {
    return [];
  }

  const db = getDb();
  const permSetDoc = await db.collection("permissionSets").doc(roleId).get();
  if (permSetDoc.exists) {
    return permSetDoc.data().permissions || [];
  }

  const byName = await db
    .collection("permissionSets")
    .where("name", "==", roleId)
    .limit(1)
    .get();

  if (!byName.empty) {
    return byName.docs[0].data().permissions || [];
  }

  return [];
}

exports.createAppUser = functions.https.onCall(async (data, context) => {
  if (!(await callerIsAdmin(context))) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only administrators can create user accounts."
    );
  }

  const email = (data.email || "").trim().toLowerCase();
  const displayName = (data.displayName || "").trim();
  const departmentId = data.departmentId || null;
  const roleId = data.roleId || null;
  const suppliedPassword = (data.password || "").trim();

  if (!email || !email.includes("@")) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "A valid email address is required."
    );
  }

  if (!displayName) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Display name is required."
    );
  }

  const temporaryPassword =
    suppliedPassword.length >= 8 ? suppliedPassword : generateTemporaryPassword();

  let userRecord;
  try {
    userRecord = await getAuth().createUser({
      email,
      password: temporaryPassword,
      displayName,
      emailVerified: false,
      disabled: false,
    });
  } catch (error) {
    if (error.code === "auth/email-already-exists") {
      throw new functions.https.HttpsError(
        "already-exists",
        "An account with this email already exists."
      );
    }
    throw new functions.https.HttpsError(
      "internal",
      error.message || "Failed to create authentication account."
    );
  }

  const permissions = await resolvePermissionsForRole(roleId);
  const customClaims = {};
  if (permissions.includes("admin") || permissions.includes("*")) {
    customClaims.admin = true;
  }

  try {
    if (Object.keys(customClaims).length > 0) {
      await getAuth().setCustomUserClaims(userRecord.uid, customClaims);
    }

    await getDb()
      .collection("users")
      .doc(userRecord.uid)
      .set({
        email,
        name: displayName,
        displayName,
        department: departmentId,
        departmentId,
        roleId,
        role: roleId,
        permissions,
        isActive: true,
        isDisabled: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdBy: context.auth.uid,
      });
  } catch (error) {
    await getAuth().deleteUser(userRecord.uid).catch(() => undefined);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to save user profile. Auth account was rolled back."
    );
  }

  return {
    uid: userRecord.uid,
    temporaryPassword: suppliedPassword.length >= 8 ? null : temporaryPassword,
  };
});
