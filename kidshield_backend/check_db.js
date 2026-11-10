const mongoose = require('mongoose');

const uri = 'mongodb+srv://emp:admin123@cluster0.hsiv1qu.mongodb.net/kidshield?retryWrites=true&w=majority&appName=Cluster0';

async function main() {
  try {
    await mongoose.connect(uri, { serverSelectionTimeoutMS: 5000 });
    const db = mongoose.connection.db;
    const childId = new mongoose.Types.ObjectId('6aeb10e7a5db5e63a2f80c6e');

    const apps = await db.collection('installedapps').find({ childId }).toArray();
    console.log('Installed apps total for child:', apps.length);
    console.log(apps.slice(0, 10).map(a => ({ name: a.appName, pkg: a.packageName, approved: a.isParentApproved, newly: a.isNewlyInstalled })));

    const locations = await db.collection('locations').find({ childId }).sort({ timestamp: -1 }).limit(3).toArray();
    console.log('Latest locations:', locations.map(l => ({ lat: l.latitude, lng: l.longitude, addr: l.address, time: l.timestamp })));

    await mongoose.disconnect();
    process.exit(0);
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
}

main();
