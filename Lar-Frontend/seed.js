const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: serviceAccount.project_id
});

const auth = admin.auth();
const db = admin.firestore();

async function seedDatabase() {
  try {
    console.log('🌱 Starting Firebase database seeding...\n');

    // Create Admin User
    console.log('👤 Creating admin user...');
    let adminUid;
    try {
      const adminUser = await auth.createUser({
        email: 'admin@rescuenet.com',
        password: 'password123',
        displayName: 'Admin User'
      });
      adminUid = adminUser.uid;
      console.log('✓ Created admin user:', adminUid);
    } catch (error) {
      if (error.code === 'auth/email-already-exists') {
        console.log('ℹ Admin user already exists, fetching UID...');
        const adminUser = await auth.getUserByEmail('admin@rescuenet.com');
        adminUid = adminUser.uid;
      } else {
        throw error;
      }
    }

    // Create Citizen User
    console.log('\n👤 Creating citizen user...');
    let citizenUid;
    try {
      const citizenUser = await auth.createUser({
        email: 'citizen@rescuenet.com',
        password: 'password123',
        displayName: 'John Citizen'
      });
      citizenUid = citizenUser.uid;
      console.log('✓ Created citizen user:', citizenUid);
    } catch (error) {
      if (error.code === 'auth/email-already-exists') {
        console.log('ℹ Citizen user already exists, fetching UID...');
        const citizenUser = await auth.getUserByEmail('citizen@rescuenet.com');
        citizenUid = citizenUser.uid;
      } else {
        throw error;
      }
    }

    // Create Admin Profile in Firestore
    console.log('\n📋 Creating admin profile...');
    await db.collection('users').doc(adminUid).set({
      full_name: 'Admin User',
      ic_no: '960115-12-1234',
      phone_no: '0123456789',
      address: 'Admin Office, Lubok Antu',
      email: 'admin@rescuenet.com',
      role: 'admin',
      status: 'active',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    });
    console.log('✓ Created admin profile');

    // Create Citizen Profile in Firestore
    console.log('\n📋 Creating citizen profile...');
    await db.collection('users').doc(citizenUid).set({
      full_name: 'John Citizen',
      ic_no: '980225-08-5678',
      phone_no: '0129876543',
      address: 'Block A, Jalan Sejahtera, Lubok Antu',
      email: 'citizen@rescuenet.com',
      role: 'resident',
      status: 'active',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    });
    console.log('✓ Created citizen profile');

    // Create Aid Programs
    console.log('\n🏥 Creating aid programs...');
    const aidPrograms = [
      {
        name: 'Medical Assistance Fund',
        description: 'Financial aid for medical emergencies',
        category: 'Health',
        status: 'active'
      },
      {
        name: 'Shelter Program',
        description: 'Emergency shelter during disasters',
        category: 'Housing',
        status: 'active'
      },
      {
        name: 'Food & Water Supply',
        description: 'Emergency food and clean water distribution',
        category: 'Food',
        status: 'active'
      }
    ];

    for (const program of aidPrograms) {
      await db.collection('aid_programs').add({
        ...program,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      });
      console.log('✓ Created program:', program.name);
    }

    // Create Sample Emergency Reports
    console.log('\n📝 Creating sample emergency reports...');
    const reports = [
      {
        title: 'Flood - Kampung Sungai Utama',
        type: 'Flood',
        location: 'Kampung Sungai Utama, Lubok Antu',
        description: 'Flash flood affecting 20+ households. Water level rising rapidly.',
        status: 'unresolved',
        priority: 'high',
        reporter_name: 'John Citizen',
        reporter_ic: '980225-08-5678',
        reporter_contact: '0129876543',
        user_id: citizenUid,
        date_reported: new Date().toISOString(),
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      },
      {
        title: 'Fire - Residential Area',
        type: 'Fire',
        location: 'Jalan Sejahtera Block A, Lubok Antu',
        description: 'House fire with thick smoke. Residents evacuated.',
        status: 'in-progress',
        priority: 'high',
        reporter_name: 'John Citizen',
        reporter_ic: '980225-08-5678',
        reporter_contact: '0129876543',
        user_id: citizenUid,
        date_reported: new Date().toISOString(),
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      },
      {
        title: 'Medical Emergency - Hospital Required',
        type: 'Medical Emergency',
        location: 'Kampung Baru, Lubok Antu',
        description: 'Elderly person with chest pain requiring immediate hospitalization.',
        status: 'resolved',
        priority: 'high',
        reporter_name: 'John Citizen',
        reporter_ic: '980225-08-5678',
        reporter_contact: '0129876543',
        user_id: citizenUid,
        date_reported: new Date().toISOString(),
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      }
    ];

    for (const report of reports) {
      const docRef = await db.collection('emergency_reports').add(report);
      console.log('✓ Created report:', report.title, '(ID:', docRef.id + ')');
    }

    console.log('\n✅ Database seeding completed successfully!');
    console.log('\n📊 Summary:');
    console.log('  • Users created: 2 (Admin + Citizen)');
    console.log('  • Aid programs created: 3');
    console.log('  • Emergency reports created: 3');
    console.log('\n🔑 Test Credentials:');
    console.log('  Admin:   admin@rescuenet.com / password123');
    console.log('  Citizen: citizen@rescuenet.com / password123');

    process.exit(0);
  } catch (error) {
    console.error('\n❌ Error seeding database:');
    console.error(error.message);
    process.exit(1);
  }
}

// Run seeding
seedDatabase();
