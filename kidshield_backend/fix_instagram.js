const mongoose = require('mongoose');
const uri = 'mongodb+srv://emp:admin123@cluster0.hsiv1qu.mongodb.net/kidshield?retryWrites=true&w=majority&appName=Cluster0';

async function fix() {
  await mongoose.connect(uri);
  const db = mongoose.connection.useDb('kidshield');
  
  const child = await db.collection('children').findOne({ name: 'Jo' });
  console.log('Child Jo:', child._id, 'Parent:', child.parentId);

  // Update Instagram
  const res = await db.collection('installedapps').updateOne(
    { childId: child._id, packageName: 'com.instagram.android' },
    { $set: { isNewlyInstalled: true, isParentApproved: false, isBlocked: true } }
  );
  console.log('Updated Instagram in installedapps:', res.modifiedCount);

  // Add to blockedPackageNames in restrictions
  await db.collection('restrictions').updateOne(
    { childId: child._id },
    { $addToSet: { blockedPackageNames: 'com.instagram.android' } }
  );
  console.log('Blocked Instagram in restrictions');

  // Create notification
  const notif = await db.collection('notifications').insertOne({
    parentId: child.parentId,
    childId: child._id,
    childName: child.name,
    type: 'appInstalled',
    severity: 'warning',
    title: '⚠️ New App Installed: Instagram',
    message: `${child.name} installed "Instagram". Parent approval required before child can use it.`,
    isRead: false,
    metadata: { packageName: 'com.instagram.android', appName: 'Instagram', requiresApproval: true },
    createdAt: new Date(),
    updatedAt: new Date()
  });
  console.log('Notification created:', notif.insertedId);

  process.exit(0);
}
fix();

