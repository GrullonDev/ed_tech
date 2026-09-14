// Rellena el campo `uid` en documentos `circles/{circleId}/members/{uid}`
// creados ANTES de este cambio (que solo tenían el uid como ID de
// documento, nunca como campo) — ver el fix de
// `HomeLogic._rehydrateCirclesFromFirestore` en lib/features/logic/logic.dart
// y `firestore.rules` (regla de lectura de `members/{uid}`). Sin este
// campo, una cuenta que ya era miembro de un círculo ANTES de este deploy
// nunca aparecería en su propia collectionGroup query al reinstalar la
// app: `_mirrorCircleCreation` y `redeemInviteCode` ya escriben el campo
// para las membresías NUEVAS a partir de ahora; este script es el
// backfill único para las que ya existían.
//
// No corre en producción ni se despliega — es una herramienta de un solo
// uso que se corre a mano, una vez, desde tu máquina. Mismos requisitos
// que scripts/seed_trivia_questions.js (Node.js + credenciales de una
// cuenta de servicio con acceso de escritura a Firestore, vía
// GOOGLE_APPLICATION_CREDENTIALS) — ver ese archivo para el detalle
// completo de cómo conseguirlas.
//
// Uso (desde la carpeta functions/):
//   node scripts/backfill_member_uid.js
//
// Es seguro correrlo más de una vez: solo toca documentos donde
// `uid` todavía no coincide con el ID de documento.

const admin = require('firebase-admin');

admin.initializeApp({ projectId: 'rachatribu' });
const db = admin.firestore();

async function backfill() {
  const snapshot = await db.collectionGroup('members').get();
  const pending = snapshot.docs.filter((doc) => doc.data().uid !== doc.id);

  if (pending.length === 0) {
    console.log('Nada que corregir: todas las membresías ya tienen el campo uid.');
    return;
  }

  const batchSize = 400; // límite de Firestore es 500 escrituras por batch
  for (let start = 0; start < pending.length; start += batchSize) {
    const batch = db.batch();
    const chunk = pending.slice(start, start + batchSize);
    chunk.forEach((doc) => batch.set(doc.ref, { uid: doc.id }, { merge: true }));
    await batch.commit();
    console.log(`Corregidas ${start + chunk.length}/${pending.length} membresías...`);
  }
  console.log(`Listo: ${pending.length} membresías actualizadas con su campo uid.`);
}

backfill()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('Falló el backfill de uid en members:', error);
    process.exit(1);
  });
