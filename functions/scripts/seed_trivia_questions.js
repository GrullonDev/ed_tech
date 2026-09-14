// Puebla la colección `triviaQuestions` de Firestore (ver
// firebase/FIRESTORE_SCHEMA.md) con el banco de preguntas del "Desafío del
// día" — ver `lib/core/data/trivia_bank.dart` para el banco local
// hardcodeado que usa la app como fallback offline; este script sube ese
// mismo contenido (extraído a `trivia_questions_seed.json`) a Firestore
// para que de ahí en más se pueda agregar/editar preguntas desde la
// consola de Firebase sin publicar una nueva versión de la app.
//
// No corre en producción ni se despliega — es una herramienta de un solo
// uso (o para reseedear si hace falta) que se corre a mano, una vez, desde
// tu máquina.
//
// Requisitos:
//   1. Node.js (el mismo que ya usás para functions/) y las dependencias
//      de functions/ instaladas (`npm install` desde functions/, si no lo
//      hiciste ya — este script usa el `firebase-admin` que ya está ahí).
//   2. Credenciales de una cuenta de servicio con acceso de escritura a
//      Firestore del proyecto rachatribu:
//        a. Consola de Google Cloud → IAM y administración → Cuentas de
//           servicio → (podés reusar una cuenta existente o crear una
//           nueva) → Agregar clave → JSON.
//        b. Rol necesario: "Cloud Datastore User" (o "Editor" si preferís
//           algo más amplio que ya tengas a mano).
//        c. Descargá el JSON y guardalo en un lugar seguro FUERA del
//           repo (nunca lo commitees).
//   3. Definir la variable de entorno GOOGLE_APPLICATION_CREDENTIALS
//      apuntando a ese archivo antes de correr el script:
//        Windows (PowerShell):
//          $env:GOOGLE_APPLICATION_CREDENTIALS = "C:\ruta\a\tu-clave.json"
//        Windows (cmd):
//          set GOOGLE_APPLICATION_CREDENTIALS=C:\ruta\a\tu-clave.json
//        macOS/Linux:
//          export GOOGLE_APPLICATION_CREDENTIALS="/ruta/a/tu-clave.json"
//
// Uso (desde la carpeta functions/):
//   node scripts/seed_trivia_questions.js
//
// Es seguro correrlo más de una vez: usa el mismo ID de documento
// determinístico por pregunta (`q-000`, `q-001`, ...), así que reemplaza
// (no duplica) si se vuelve a correr con el mismo `trivia_questions_seed.json`.

const admin = require('firebase-admin');
const questions = require('./trivia_questions_seed.json');

admin.initializeApp({ projectId: 'rachatribu' });
const db = admin.firestore();

async function seed() {
  const collection = db.collection('triviaQuestions');
  const batchSize = 400; // límite de Firestore es 500 escrituras por batch
  for (let start = 0; start < questions.length; start += batchSize) {
    const batch = db.batch();
    const chunk = questions.slice(start, start + batchSize);
    chunk.forEach((question, offset) => {
      const index = start + offset;
      const docId = `q-${String(index).padStart(3, '0')}`;
      batch.set(collection.doc(docId), question);
    });
    await batch.commit();
    console.log(`Escritas ${start + chunk.length}/${questions.length} preguntas...`);
  }
  console.log(`Listo: ${questions.length} preguntas en triviaQuestions.`);
}

seed()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('Falló el seed de triviaQuestions:', error);
    process.exit(1);
  });
