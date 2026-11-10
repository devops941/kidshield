const mongoose = require('mongoose');
const uri = 'mongodb+srv://emp:admin123@cluster0.hsiv1qu.mongodb.net/kidshield?retryWrites=true&w=majority&appName=Cluster0';

async function check() {
  await mongoose.connect(uri);
  const db = mongoose.connection.useDb('kidshield');
  const parents = await db.collection('parents').find().toArray();
  console.log('TOTAL PARENTS:', parents.length);
  for (let p of parents) {
    console.log(JSON.stringify({ id: p._id, name: p.fullName, email: p.email, phone: p.phoneNumber }));
  }
  const children = await db.collection('children').find().toArray();
  console.log('TOTAL CHILDREN:', children.length);
  for (let c of children) {
    console.log(JSON.stringify({ id: c._id, parentId: c.parentId, name: c.name, pairingCode: c.pairingCode, createdAt: c.createdAt }));
  }
  process.exit(0);
}
check();
