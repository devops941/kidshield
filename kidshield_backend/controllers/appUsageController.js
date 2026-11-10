const mongoose = require('mongoose');
const AppUsage = require('../models/AppUsage');
const DailyActivity = require('../models/DailyActivity');
const InstalledApp = require('../models/InstalledApp');
const Child = require('../models/Child');
const Restriction = require('../models/Restriction');
const Notification = require('../models/Notification');
const User = require('../models/User');
const { sendPushNotification } = require('../config/firebaseAdmin');

// In-memory fallback stores for demo profiles
const demoUsageStore = new Map();
const demoInstalledAppsStore = new Map();

// Known system launchers, desktop shells, and internal services excluded from child leisure screen time
const EXCLUDED_PACKAGES = new Set([
  'com.sec.android.app.launcher', // Samsung One UI Home
  'com.google.android.apps.nexuslauncher', // Pixel Launcher
  'com.android.launcher',
  'com.android.launcher3',
  'com.mi.android.globallauncher',
  'com.miui.home',
  'com.oppo.launcher',
  'com.coloros.launcher',
  'com.vivo.launcher',
  'com.bbk.launcher2',
  'com.huawei.android.launcher',
  'com.oneplus.launcher',
  'com.teslacoilsw.launcher',
  'com.android.systemui',
  'com.google.android.gms',
  'com.google.android.googlequicksearchbox',
  'com.google.android.inputmethod.latin',
  'com.samsung.android.honeyboard',
  'com.sec.android.inputmethod',
  'com.google.android.permissioncontroller',
  'com.android.permissioncontroller',
  'com.kidshield.parent.kidshield_parent',
  'com.kidshield.child.kidshield_child',
]);

function isExcludedApp(packageName, appName = '') {
  if (!packageName) return true;
  if (EXCLUDED_PACKAGES.has(packageName)) return true;
  const pkg = packageName.toLowerCase();
  const name = (appName || '').toLowerCase();
  if (
    pkg.includes('launcher') ||
    pkg.includes('systemui') ||
    pkg.includes('honeyboard') ||
    pkg.includes('inputmethod') ||
    pkg.includes('kidshield') ||
    name.includes('one ui home') ||
    name.includes('launcher') ||
    name.includes('system ui') ||
    name.includes('honeyboard')
  ) {
    return true;
  }
  return false;
}

// Helper to get formatted local date (YYYY-MM-DD) in specified timezone
function getLocalDateString(timeZone = 'Asia/Kolkata', date = new Date()) {
  try {
    return new Intl.DateTimeFormat('en-CA', { timeZone }).format(date);
  } catch (_) {
    return date.toISOString().split('T')[0];
  }
}

// No fake top apps
function getDefaultTopApps(childId) {
  return [];
}

// @desc    Sync app usage statistics from Child phone
// @route   POST /api/app-usage/sync
// @access  Public (Child Device)
exports.syncAppUsage = async (req, res, next) => {
  try {
    const { childId, usageData, date, timezone, totalMinutesToday: incomingTotalMinutes } = req.body;

    if (!childId || !Array.isArray(usageData)) {
      return res.status(400).json({ success: false, message: 'Please provide childId and usageData array' });
    }

    const tz = timezone || 'Asia/Kolkata';
    const recordDate = date || getLocalDateString(tz);

    // Filter out system launchers and excluded apps from active screen time
    const validUsageData = usageData.filter((item) => !isExcludedApp(item.packageName, item.appName));

    // Calculate accurate non-overlapping device screen time strictly from valid apps
    let totalMinutesToday = validUsageData.reduce((sum, item) => sum + (item.usageMinutesToday || 0), 0);
    if (typeof incomingTotalMinutes === 'number' && incomingTotalMinutes >= 0 && incomingTotalMinutes < 1440) {
      if (incomingTotalMinutes <= totalMinutesToday) {
        totalMinutesToday = incomingTotalMinutes;
      }
    }

    // Handle non-ObjectId or demo children
    if (!mongoose.Types.ObjectId.isValid(childId)) {
      demoUsageStore.set(childId, validUsageData);
      return res.status(200).json({
        success: true,
        message: 'App usage synced (demo profile)',
        date: recordDate,
        totalMinutesToday,
      });
    }

    const child = await Child.findById(childId);
    if (!child) {
      return res.status(404).json({ success: false, message: 'Child not found' });
    }

    // 1. Idempotently upsert date-partitioned DailyActivity record with valid apps only
    await DailyActivity.findOneAndUpdate(
      { childId, date: recordDate },
      {
        childId,
        date: recordDate,
        timezone: tz,
        totalScreenTimeMinutes: totalMinutesToday,
        appBreakdown: validUsageData.map((item) => ({
          packageName: item.packageName,
          appName: item.appName || item.packageName,
          category: item.category || 'General',
          icon: item.icon || '',
          usageMinutes: item.usageMinutesToday || 0,
          launchCount: item.launchCountToday || 0,
        })),
        lastSyncedAt: new Date(),
      },
      { upsert: true, new: true }
    );

    // 2. Update AppUsage collection for backwards compatibility with existing Parent UI
    for (const item of validUsageData) {
      await AppUsage.findOneAndUpdate(
        { childId, packageName: item.packageName },
        {
          childId,
          packageName: item.packageName,
          appName: item.appName || item.packageName,
          category: item.category || 'General',
          icon: item.icon || '',
          usageMinutesToday: item.usageMinutesToday || 0,
          usageMinutesWeekly: item.usageMinutesWeekly || 0,
          usageMinutesMonthly: item.usageMinutesMonthly || 0,
          launchCountToday: item.launchCountToday || 0,
          lastSyncDate: recordDate,
          lastUsed: new Date(),
        },
        { upsert: true, new: true }
      );
    }

    // Check if daily screen time exceeded
    if (totalMinutesToday >= child.dailyScreenTimeLimitMinutes) {
      const parent = await User.findById(child.parentId);
      const title = `⏳ Daily Screen Time Limit Reached: ${child.name}`;
      const message = `${child.name} has exceeded today's screen time limit of ${(child.dailyScreenTimeLimitMinutes / 60).toFixed(1)} hours.`;

      await Notification.create({
        parentId: child.parentId,
        childId: child._id,
        childName: child.name,
        type: 'screenTimeLimit',
        severity: 'warning',
        title,
        message,
        metadata: { totalMinutesToday, limit: child.dailyScreenTimeLimitMinutes, date: recordDate },
      });

      if (parent && parent.fcmToken) {
        await sendPushNotification(parent.fcmToken, {
          title,
          body: message,
          data: { type: 'screenTimeLimit', childId: String(child._id), date: recordDate },
        });
      }
    }

    res.status(200).json({
      success: true,
      message: 'App usage and daily activity synced successfully',
      date: recordDate,
      totalMinutesToday,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get app usage statistics for a child
// @route   GET /api/app-usage/:childId
// @access  Public or Private
exports.getAppUsage = async (req, res, next) => {
  try {
    const { childId } = req.params;
    const { date: queryDate, timezone } = req.query;
    const tz = timezone || 'Asia/Kolkata';
    const targetDate = queryDate || getLocalDateString(tz);

    if (!mongoose.Types.ObjectId.isValid(childId)) {
      const demo = (demoUsageStore.get(childId) || getDefaultTopApps(childId))
        .filter((item) => !isExcludedApp(item.packageName, item.appName));
      const totalMinutesToday = demo.reduce((sum, item) => sum + (item.usageMinutesToday || 0), 0);
      return res.status(200).json({
        success: true,
        date: targetDate,
        totalMinutesToday,
        totalMinutesWeekly: totalMinutesToday * 3,
        totalMinutesMonthly: totalMinutesToday * 10,
        weeklyBreakdown: {
          labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
          values: [0, totalMinutesToday, 0, 0, 0, 0, 0],
        },
        monthlyBreakdown: {
          labels: ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
          values: [0, 0, 0, totalMinutesToday],
        },
        count: demo.length,
        usage: demo,
      });
    }

    // 1. Fetch exact date-partitioned DailyActivity if available
    const dailyRecord = await DailyActivity.findOne({ childId, date: targetDate });

    let usage = await AppUsage.find({ childId }).sort({ usageMinutesToday: -1 });

    // Filter out excluded launcher/system packages
    usage = usage.filter((item) => !isExcludedApp(item.packageName, item.appName));

    // 2. Calculate real today total from active apps
    let totalMinutesToday = usage.reduce((sum, item) => {
      if (item.lastSyncDate === targetDate) {
        return sum + (item.usageMinutesToday || 0);
      }
      return sum;
    }, 0);

    if (dailyRecord && dailyRecord.totalScreenTimeMinutes > 0) {
      const validInRecord = (dailyRecord.appBreakdown || [])
        .filter((a) => !isExcludedApp(a.packageName, a.appName))
        .reduce((sum, a) => sum + (a.usageMinutes || 0), 0);
      if (validInRecord > 0) {
        totalMinutesToday = validInRecord;
      }
    }

    // 3. Sanitize individual apps: If an app has not been synced today, its usageMinutesToday is 0
    const sanitizedUsage = usage.map((item) => {
      const isCurrentDay = item.lastSyncDate === targetDate;
      const obj = item.toObject();
      if (!isCurrentDay) {
        obj.usageMinutesToday = 0;
        obj.launchCountToday = 0;
      }
      return obj;
    });

    const totalMinutesWeekly = sanitizedUsage.reduce((sum, item) => sum + (item.usageMinutesWeekly || 0), 0);
    const totalMinutesMonthly = sanitizedUsage.reduce((sum, item) => sum + (item.usageMinutesMonthly || 0), 0);

    // 4. Fetch real past 30 days DailyActivity records to build exact Monday-Sunday and 4-week breakdowns
    const pastRecords = await DailyActivity.find({ childId }).sort({ date: 1 });
    const recordsMap = new Map();
    for (const r of pastRecords) {
      const cleanMinutes = (r.appBreakdown || [])
        .filter((a) => !isExcludedApp(a.packageName, a.appName))
        .reduce((s, a) => s + (a.usageMinutes || 0), 0);
      recordsMap.set(r.date, cleanMinutes > 0 ? cleanMinutes : (r.totalScreenTimeMinutes <= 1440 ? r.totalScreenTimeMinutes : 0));
    }
    // Set today's sanitized total
    recordsMap.set(targetDate, totalMinutesToday);

    // Calculate Monday-Sunday for current week
    const nowTarget = new Date(`${targetDate}T12:00:00Z`);
    const dayOfWeek = (nowTarget.getUTCDay() + 6) % 7; // 0 = Mon, 6 = Sun
    const monday = new Date(nowTarget);
    monday.setUTCDate(nowTarget.getUTCDate() - dayOfWeek);

    const weeklyValues = [];
    for (let i = 0; i < 7; i++) {
      const d = new Date(monday);
      d.setUTCDate(monday.getUTCDate() + i);
      const dateStr = d.toISOString().split('T')[0];
      weeklyValues.push(recordsMap.get(dateStr) || 0);
    }

    // Calculate 4-week monthly breakdown (Week 1 to Week 4)
    const monthlyValues = [0, 0, 0, 0];
    for (let w = 0; w < 4; w++) {
      let weekSum = 0;
      for (let dayOffset = 0; dayOffset < 7; dayOffset++) {
        const d = new Date(nowTarget);
        const daysAgo = (3 - w) * 7 + dayOffset;
        d.setUTCDate(nowTarget.getUTCDate() - daysAgo);
        const dateStr = d.toISOString().split('T')[0];
        weekSum += (recordsMap.get(dateStr) || 0);
      }
      monthlyValues[w] = weekSum;
    }
    if (monthlyValues[3] === 0 && totalMinutesWeekly > 0) {
      monthlyValues[3] = totalMinutesWeekly;
    }

    res.status(200).json({
      success: true,
      date: targetDate,
      totalMinutesToday,
      totalMinutesWeekly,
      totalMinutesMonthly,
      weeklyBreakdown: {
        labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        values: weeklyValues,
      },
      monthlyBreakdown: {
        labels: ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
        values: monthlyValues,
      },
      count: sanitizedUsage.length,
      usage: sanitizedUsage,
      dailyRecord: dailyRecord || null,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get historical daily screen time activity for a child
// @route   GET /api/app-usage/:childId/daily-history
// @access  Public or Private
exports.getDailyActivityHistory = async (req, res, next) => {
  try {
    const { childId } = req.params;
    const { limit = 14 } = req.query;

    if (!mongoose.Types.ObjectId.isValid(childId)) {
      return res.status(200).json({ success: true, count: 0, records: [] });
    }

    const records = await DailyActivity.find({ childId })
      .sort({ date: -1 })
      .limit(parseInt(limit, 10));

    res.status(200).json({
      success: true,
      count: records.length,
      records,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Sync installed apps from Child device
// @route   POST /api/installed-apps/sync
// @access  Public (Child Device)
exports.syncInstalledApps = async (req, res, next) => {
  try {
    const { childId, apps, isNewInstall } = req.body;

    if (!childId || !Array.isArray(apps)) {
      return res.status(400).json({ success: false, message: 'Please provide childId and apps array' });
    }

    if (!mongoose.Types.ObjectId.isValid(childId)) {
      demoInstalledAppsStore.set(childId, apps);
      return res.status(200).json({ success: true, message: 'Installed apps processed (demo profile)' });
    }

    const child = await Child.findById(childId);
    if (!child) {
      return res.status(404).json({ success: false, message: 'Child not found' });
    }

    const existingCount = await InstalledApp.countDocuments({ childId });

    // 1. Explicit New App Installation Event from AppInstallReceiver
    if (isNewInstall === true) {
      for (const app of apps) {
        let existing = await InstalledApp.findOne({ childId, packageName: app.packageName });
        if (!existing) {
          existing = await InstalledApp.create({
            childId,
            packageName: app.packageName,
            appName: app.appName,
            icon: app.icon || '',
            versionName: app.versionName || '1.0',
            ageRating: app.ageRating || 'Everyone',
            isNewlyInstalled: true,
            isParentApproved: false,
            isBlocked: true,
          });
        } else {
          existing.isNewlyInstalled = true;
          existing.isParentApproved = false;
          existing.isBlocked = true;
          if (app.icon) existing.icon = app.icon;
          await existing.save();
        }

        // Immediately block in restrictions until approved
        await Restriction.findOneAndUpdate(
          { childId },
          { $addToSet: { blockedPackageNames: app.packageName } }
        );

        const parent = await User.findById(child.parentId);
        const title = `⚠️ New App Installed: ${app.appName}`;
        const message = `${child.name} installed "${app.appName}". Parent approval required before child can use it.`;

        await Notification.create({
          parentId: child.parentId,
          childId: child._id,
          childName: child.name,
          type: 'appInstalled',
          severity: 'warning',
          title,
          message,
          metadata: { packageName: app.packageName, appName: app.appName, requiresApproval: true },
        });

        if (parent && parent.fcmToken) {
          await sendPushNotification(parent.fcmToken, {
            title,
            body: message,
            data: { type: 'appInstalled', childId: String(child._id), packageName: app.packageName },
          });
        }
      }
      return res.status(200).json({ success: true, message: 'New app install processed with parent notification' });
    }

    // 2. Routine Full Inventory Sync:
    // If existingCount === 0: This is the very first baseline sync after pairing.
    // All apps are pre-existing phone apps, mark them approved.
    // If existingCount > 0: Any app NOT previously in the database is a NEW INSTALL!
    const isFirstTimeBaseline = existingCount === 0;

    for (const app of apps) {
      const existing = await InstalledApp.findOne({ childId, packageName: app.packageName });
      if (!existing) {
        if (isFirstTimeBaseline) {
          // Pre-existing app on the child phone before pairing
          await InstalledApp.create({
            childId,
            packageName: app.packageName,
            appName: app.appName,
            icon: app.icon || '',
            versionName: app.versionName || '1.0',
            ageRating: app.ageRating || 'Everyone',
            isNewlyInstalled: false,
            isParentApproved: true,
            isBlocked: false,
          });
        } else {
          // Brand new app downloaded after baseline!
          console.log(`[AppSync] Newly detected installed app during sync: ${app.appName} (${app.packageName})`);
          await InstalledApp.create({
            childId,
            packageName: app.packageName,
            appName: app.appName,
            icon: app.icon || '',
            versionName: app.versionName || '1.0',
            ageRating: app.ageRating || 'Everyone',
            isNewlyInstalled: true,
            isParentApproved: false,
            isBlocked: true,
          });

          // Block until approved
          await Restriction.findOneAndUpdate(
            { childId },
            { $addToSet: { blockedPackageNames: app.packageName } }
          );

          // Create notification for parent
          const parent = await User.findById(child.parentId);
          const title = `⚠️ New App Installed: ${app.appName}`;
          const message = `${child.name} installed "${app.appName}". Parent approval required before child can use it.`;

          await Notification.create({
            parentId: child.parentId,
            childId: child._id,
            childName: child.name,
            type: 'appInstalled',
            severity: 'warning',
            title,
            message,
            metadata: { packageName: app.packageName, appName: app.appName, requiresApproval: true },
          });

          if (parent && parent.fcmToken) {
            await sendPushNotification(parent.fcmToken, {
              title,
              body: message,
              data: { type: 'appInstalled', childId: String(child._id), packageName: app.packageName },
            });
          }
        }
      } else {
        // App already exists in database. Update icon/version if needed.
        // DO NOT overwrite isNewlyInstalled or isParentApproved if waiting for approval!
        if (app.icon && (!existing.icon || existing.icon.length < app.icon.length)) {
          existing.icon = app.icon;
          await existing.save();
        }
      }
    }

    res.status(200).json({ success: true, message: 'Installed apps inventory synced successfully' });
  } catch (error) {
    next(error);
  }
};

// @desc    Get installed apps list
// @route   GET /api/installed-apps/:childId
// @access  Public or Private
exports.getInstalledApps = async (req, res, next) => {
  try {
    const { childId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(childId)) {
      const demo = demoInstalledAppsStore.get(childId) || [];
      return res.status(200).json({
        success: true,
        count: demo.length,
        apps: demo,
      });
    }

    // Auto-heal: Ensure all existing built-in / pre-installed phone apps are marked as approved
    await InstalledApp.updateMany(
      {
        childId,
        isNewlyInstalled: true,
        $or: [
          { packageName: { $regex: /^(com\.sec|com\.samsung|com\.android|com\.google|com\.tmobile)/i } },
          { appName: { $in: ['Files', 'Safety', 'TMobile', 'Phone', 'Clock', 'Contacts', 'Calendar', 'YT Music', 'Settings', 'One UI Home', 'Messages', 'Camera', 'Gallery'] } }
        ]
      },
      {
        $set: { isNewlyInstalled: false, isParentApproved: true, isBlocked: false }
      }
    );

    // Remove unblocked packages from restrictions
    const unblockedApps = await InstalledApp.find({ childId, isBlocked: false }).select('packageName');
    if (unblockedApps.length > 0) {
      const unblockedPkgs = unblockedApps.map(a => a.packageName);
      await Restriction.findOneAndUpdate(
        { childId },
        { $pull: { blockedPackageNames: { $in: unblockedPkgs } } }
      );
    }

    const apps = await InstalledApp.find({ childId }).sort({ installedAt: -1 });

    res.status(200).json({
      success: true,
      count: (apps || []).length,
      apps: apps || [],
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Toggle block status of an app
// @route   PUT /api/installed-apps/:childId/block
// @access  Private (Parent)
exports.toggleAppBlock = async (req, res, next) => {
  try {
    const { packageName, isBlocked } = req.body;
    const app = await InstalledApp.findOneAndUpdate(
      { childId: req.params.childId, packageName },
      { isBlocked },
      { new: true }
    );
    if (!app) {
      return res.status(404).json({ success: false, message: 'App not found on child device' });
    }

    if (isBlocked) {
      await Restriction.findOneAndUpdate(
        { childId: req.params.childId },
        { $addToSet: { blockedPackageNames: packageName } }
      );
    } else {
      await Restriction.findOneAndUpdate(
        { childId: req.params.childId },
        { $pull: { blockedPackageNames: packageName } }
      );
    }

    res.status(200).json({ success: true, message: `App ${isBlocked ? 'blocked' : 'unblocked'} successfully`, app });
  } catch (error) {
    next(error);
  }
};

// @desc    Approve a newly installed app
// @route   PUT /api/installed-apps/:childId/approve
// @access  Private (Parent)
exports.approveApp = async (req, res, next) => {
  try {
    const { packageName } = req.body;
    const app = await InstalledApp.findOneAndUpdate(
      { childId: req.params.childId, packageName },
      { isParentApproved: true, isNewlyInstalled: false, isBlocked: false },
      { new: true }
    );
    if (!app) {
      return res.status(404).json({ success: false, message: 'App not found' });
    }

    // Unblock in restrictions
    await Restriction.findOneAndUpdate(
      { childId: req.params.childId },
      { $pull: { blockedPackageNames: packageName } }
    );

    const child = await Child.findById(req.params.childId);
    const appDisplayName = app.appName || packageName;

    // Create notification for child device
    if (child) {
      await Notification.create({
        parentId: child.parentId,
        childId: child._id,
        childName: child.name,
        type: 'appApproved',
        target: 'child',
        severity: 'info',
        title: '✅ App Approved by Parent',
        message: `Your parent approved "${appDisplayName}". You can now open and use it freely.`,
        metadata: { packageName, appName: appDisplayName },
      });
    }

    res.status(200).json({ success: true, message: 'App approved successfully', app });
  } catch (error) {
    next(error);
  }
};

// @desc    Reject / Disallow a newly installed app
// @route   PUT /api/installed-apps/:childId/reject
// @access  Private (Parent)
exports.rejectApp = async (req, res, next) => {
  try {
    const { packageName } = req.body;
    const app = await InstalledApp.findOneAndUpdate(
      { childId: req.params.childId, packageName },
      { isParentApproved: false, isNewlyInstalled: false, isBlocked: true },
      { new: true }
    );
    if (!app) {
      return res.status(404).json({ success: false, message: 'App not found' });
    }

    // Ensure it is in blockedPackageNames
    await Restriction.findOneAndUpdate(
      { childId: req.params.childId },
      { $addToSet: { blockedPackageNames: packageName } }
    );

    const child = await Child.findById(req.params.childId);
    const appDisplayName = app.appName || packageName;

    // Create notification for child device
    if (child) {
      await Notification.create({
        parentId: child.parentId,
        childId: child._id,
        childName: child.name,
        type: 'appRejected',
        target: 'child',
        severity: 'warning',
        title: '🚫 App Restricted by Parent',
        message: `Your parent restricted "${appDisplayName}". Access to this app is locked.`,
        metadata: { packageName, appName: appDisplayName },
      });
    }

    res.status(200).json({ success: true, message: 'App rejected and blocked from child use', app });
  } catch (error) {
    next(error);
  }
};
