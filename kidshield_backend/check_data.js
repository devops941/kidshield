const mongoose = require('./node_modules/mongoose');
const uri = 'mongodb+srv://emp:admin123@cluster0.hsiv1qu.mongodb.net/kidshield?retryWrites=true&w=majority&appName=Cluster0';

async function check() {
  await mongoose.connect(uri);
  const db = mongoose.connection.useDb('kidshield');
  
  const usages = await db.collection('appusages').find().toArray();
  console.log('CURRENT APP USAGES COUNT:', usages.length);
  for (let u of usages) {
    console.log(`  - ${u.appName} (${u.packageName}): ${u.usageMinutesToday}m today, ${u.usageMinutesWeekly}m weekly`);
  }

  const installed = await db.collection('installedapps').find().toArray();
  console.log('CURRENT INSTALLED APPS COUNT:', installed.length);
  for (let a of installed) {
    console.log(`  - ${a.appName} (${a.packageName}) approved: ${a.isParentApproved}`);
  }

  process.exit(0);
}

check();

