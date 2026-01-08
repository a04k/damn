/**
 * Database Seed Script
 * Egyptian Science Faculty Structure
 * Run with: npm run prisma:seed
 */
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting database seed...\n');

  // ============ CREATE FACULTY ============
  console.log('📁 Creating faculty...');
  
  const scienceFaculty = await prisma.faculty.upsert({
    where: { code: 'SCI' },
    update: {},
    create: {
      code: 'SCI',
      name: 'Faculty of Science',
      nameAr: 'كلية العلوم',
      description: 'Faculty of Science offering programs in Mathematics, Physics, Chemistry, and Biology'
    }
  });

  console.log('✅ Faculty created');

  // ============ CREATE DEPARTMENTS ============
  console.log('🏢 Creating departments...');

  const mathDept = await prisma.department.upsert({
    where: { code: 'MATH' },
    update: {},
    create: {
      code: 'MATH',
      name: 'Mathematics Department',
      nameAr: 'قسم الرياضيات',
      description: 'Department of Mathematics offering Computer Science, Statistics, and Pure Mathematics programs',
      facultyId: scienceFaculty.id
    }
  });

  const bioDept = await prisma.department.upsert({
    where: { code: 'BIO' },
    update: {},
    create: {
      code: 'BIO',
      name: 'Biology Department',
      nameAr: 'قسم الأحياء',
      description: 'Department of Biology offering Zoology, Botany, and Microbiology programs',
      facultyId: scienceFaculty.id
    }
  });

  const chemDept = await prisma.department.upsert({
    where: { code: 'CHEM' },
    update: {},
    create: {
      code: 'CHEM',
      name: 'Chemistry Department',
      nameAr: 'قسم الكيمياء',
      description: 'Department of Chemistry offering Applied Chemistry and Biochemistry programs',
      facultyId: scienceFaculty.id
    }
  });

  const physDept = await prisma.department.upsert({
    where: { code: 'PHYS' },
    update: {},
    create: {
      code: 'PHYS',
      name: 'Physics Department',
      nameAr: 'قسم الفيزياء',
      description: 'Department of Physics offering Biophysics, Electronics, and Pure Physics programs',
      facultyId: scienceFaculty.id
    }
  });

  console.log('✅ Departments created');

  // ============ CREATE PROGRAMS (Specializations) ============
  console.log('📚 Creating programs...');

  // Mathematics Department Programs
  const csProgram = await prisma.program.upsert({
    where: { code: 'CS' },
    update: {},
    create: {
      code: 'CS',
      name: 'Computer Science',
      nameAr: 'علوم الحاسب',
      description: 'Computer Science program focusing on programming, algorithms, and software development',
      creditHours: 136,
      departmentId: mathDept.id
    }
  });

  const statsProgram = await prisma.program.upsert({
    where: { code: 'STAT' },
    update: {},
    create: {
      code: 'STAT',
      name: 'Statistics',
      nameAr: 'الإحصاء',
      description: 'Statistics program focusing on probability, data analysis, and statistical methods',
      creditHours: 132,
      departmentId: mathDept.id
    }
  });

  const pureMathProgram = await prisma.program.upsert({
    where: { code: 'PMATH' },
    update: {},
    create: {
      code: 'PMATH',
      name: 'Pure Mathematics',
      nameAr: 'الرياضيات البحتة',
      description: 'Pure Mathematics program focusing on algebra, analysis, and topology',
      creditHours: 132,
      departmentId: mathDept.id
    }
  });

  // Biology Department Programs
  const zooProgram = await prisma.program.upsert({
    where: { code: 'ZOO' },
    update: {},
    create: {
      code: 'ZOO',
      name: 'Zoology',
      nameAr: 'الحيوان',
      description: 'Zoology program focusing on animal biology, physiology, and evolution',
      creditHours: 132,
      departmentId: bioDept.id
    }
  });

  const botProgram = await prisma.program.upsert({
    where: { code: 'BOT' },
    update: {},
    create: {
      code: 'BOT',
      name: 'Botany',
      nameAr: 'النبات',
      description: 'Botany program focusing on plant biology, ecology, and genetics',
      creditHours: 132,
      departmentId: bioDept.id
    }
  });

  const microProgram = await prisma.program.upsert({
    where: { code: 'MICRO' },
    update: {},
    create: {
      code: 'MICRO',
      name: 'Microbiology',
      nameAr: 'الميكروبيولوجي',
      description: 'Microbiology program focusing on bacteria, viruses, and immunology',
      creditHours: 136,
      departmentId: bioDept.id
    }
  });

  // Chemistry Department Programs
  const appChemProgram = await prisma.program.upsert({
    where: { code: 'ACHEM' },
    update: {},
    create: {
      code: 'ACHEM',
      name: 'Applied Chemistry',
      nameAr: 'الكيمياء التطبيقية',
      description: 'Applied Chemistry program focusing on industrial and environmental chemistry',
      creditHours: 134,
      departmentId: chemDept.id
    }
  });

  const bioChemProgram = await prisma.program.upsert({
    where: { code: 'BCHEM' },
    update: {},
    create: {
      code: 'BCHEM',
      name: 'Biochemistry',
      nameAr: 'الكيمياء الحيوية',
      description: 'Biochemistry program focusing on molecular biology and biochemical processes',
      creditHours: 136,
      departmentId: chemDept.id
    }
  });

  console.log('✅ Programs created');

  // ============ CREATE ADMIN USER ============
  console.log('👤 Creating users...');
  
  const adminPassword = await bcrypt.hash(process.env.ADMIN_PASSWORD || 'admin123', 12);
  
  const admin = await prisma.user.upsert({
    where: { email: 'admin@college.edu' },
    update: {},
    create: {
      email: 'admin@college.edu',
      password: adminPassword,
      name: 'System Administrator',
      nameAr: 'مدير النظام',
      role: 'ADMIN',
      isVerified: true,
      isOnboardingComplete: true
    }
  });

  // ============ CREATE PROFESSORS ============
  const professorPassword = await bcrypt.hash('professor123', 12);

  // Math Department Professors
  const drAhmed = await prisma.user.upsert({
    where: { email: 'dr.ahmed@college.edu' },
    update: {},
    create: {
      email: 'dr.ahmed@college.edu',
      password: professorPassword,
      name: 'Dr. Ahmed Hassan',
      nameAr: 'د. أحمد حسن',
      role: 'PROFESSOR',
      departmentId: mathDept.id,
      isVerified: true,
      isOnboardingComplete: true
    }
  });

  const drMohamed = await prisma.user.upsert({
    where: { email: 'dr.mohamed@college.edu' },
    update: {},
    create: {
      email: 'dr.mohamed@college.edu',
      password: professorPassword,
      name: 'Dr. Mohamed Ali',
      nameAr: 'د. محمد علي',
      role: 'PROFESSOR',
      departmentId: mathDept.id,
      isVerified: true,
      isOnboardingComplete: true
    }
  });

  // Biology Department Professor
  const drSara = await prisma.user.upsert({
    where: { email: 'dr.sara@college.edu' },
    update: {},
    create: {
      email: 'dr.sara@college.edu',
      password: professorPassword,
      name: 'Dr. Sara Ibrahim',
      nameAr: 'د. سارة إبراهيم',
      role: 'PROFESSOR',
      departmentId: bioDept.id,
      isVerified: true,
      isOnboardingComplete: true
    }
  });

  // Chemistry Department Professor
  const drKhalid = await prisma.user.upsert({
    where: { email: 'dr.khalid@college.edu' },
    update: {},
    create: {
      email: 'dr.khalid@college.edu',
      password: professorPassword,
      name: 'Dr. Khalid Mahmoud',
      nameAr: 'د. خالد محمود',
      role: 'PROFESSOR',
      departmentId: chemDept.id,
      isVerified: true,
      isOnboardingComplete: true
    }
  });

  console.log('✅ Professors created');

  // ============ ASSIGN PROFESSORS TO PROGRAMS ============
  console.log('👨‍🏫 Assigning professors to programs...');

  // Dr. Ahmed can teach in CS and Statistics programs
  await prisma.programInstructor.upsert({
    where: { professorId_programId: { professorId: drAhmed.id, programId: csProgram.id } },
    update: {},
    create: { professorId: drAhmed.id, programId: csProgram.id }
  });
  await prisma.programInstructor.upsert({
    where: { professorId_programId: { professorId: drAhmed.id, programId: statsProgram.id } },
    update: {},
    create: { professorId: drAhmed.id, programId: statsProgram.id }
  });

  // Dr. Mohamed can teach in CS and Pure Math programs
  await prisma.programInstructor.upsert({
    where: { professorId_programId: { professorId: drMohamed.id, programId: csProgram.id } },
    update: {},
    create: { professorId: drMohamed.id, programId: csProgram.id }
  });
  await prisma.programInstructor.upsert({
    where: { professorId_programId: { professorId: drMohamed.id, programId: pureMathProgram.id } },
    update: {},
    create: { professorId: drMohamed.id, programId: pureMathProgram.id }
  });

  // Dr. Sara can teach in Zoology and Microbiology
  await prisma.programInstructor.upsert({
    where: { professorId_programId: { professorId: drSara.id, programId: zooProgram.id } },
    update: {},
    create: { professorId: drSara.id, programId: zooProgram.id }
  });
  await prisma.programInstructor.upsert({
    where: { professorId_programId: { professorId: drSara.id, programId: microProgram.id } },
    update: {},
    create: { professorId: drSara.id, programId: microProgram.id }
  });

  // Dr. Khalid can teach in Applied Chemistry and Biochemistry
  await prisma.programInstructor.upsert({
    where: { professorId_programId: { professorId: drKhalid.id, programId: appChemProgram.id } },
    update: {},
    create: { professorId: drKhalid.id, programId: appChemProgram.id }
  });
  await prisma.programInstructor.upsert({
    where: { professorId_programId: { professorId: drKhalid.id, programId: bioChemProgram.id } },
    update: {},
    create: { professorId: drKhalid.id, programId: bioChemProgram.id }
  });

  console.log('✅ Professors assigned to programs');

  // ============ CREATE STUDENTS ============
  const studentPassword = await bcrypt.hash('student123', 12);

  const student1 = await prisma.user.upsert({
    where: { email: 'student@college.edu' },
    update: { departmentId: mathDept.id },
    create: {
      email: 'student@college.edu',
      password: studentPassword,
      name: 'Ahmed Mohamed',
      nameAr: 'أحمد محمد',
      role: 'STUDENT',
      studentId: '20250001',
      programId: csProgram.id,
      departmentId: mathDept.id,
      level: 3,
      gpa: 3.45,
      isVerified: true,
      isOnboardingComplete: true
    }
  });

  const student2 = await prisma.user.upsert({
    where: { email: 'mona@college.edu' },
    update: { departmentId: mathDept.id },
    create: {
      email: 'mona@college.edu',
      password: studentPassword,
      name: 'Mona Ali',
      nameAr: 'منى علي',
      role: 'STUDENT',
      studentId: '20250002',
      programId: csProgram.id,
      departmentId: mathDept.id,
      level: 2,
      gpa: 3.78,
      isVerified: true,
      isOnboardingComplete: true
    }
  });

  const student3 = await prisma.user.upsert({
    where: { email: 'omar@college.edu' },
    update: { departmentId: mathDept.id },
    create: {
      email: 'omar@college.edu',
      password: studentPassword,
      name: 'Omar Khaled',
      nameAr: 'عمر خالد',
      role: 'STUDENT',
      studentId: '20250003',
      programId: statsProgram.id,
      departmentId: mathDept.id,
      level: 4,
      gpa: 3.12,
      isVerified: true,
      isOnboardingComplete: true
    }
  });

  console.log('✅ Students created');

  // ============ CREATE COURSES ============
  console.log('📖 Creating courses...');

  const cs101 = await prisma.course.upsert({
    where: { code: 'CS101' },
    update: {},
    create: {
      code: 'CS101',
      name: 'Introduction to Programming',
      nameAr: 'مقدمة في البرمجة',
      description: 'Learn programming fundamentals using Python',
      category: 'COMP',
      creditHours: 3,
      departmentId: mathDept.id,
      programId: csProgram.id,
      semester: 'Fall',
      academicYear: '2024-2025'
    }
  });

  const cs201 = await prisma.course.upsert({
    where: { code: 'CS201' },
    update: {},
    create: {
      code: 'CS201',
      name: 'Data Structures & Algorithms',
      nameAr: 'هياكل البيانات والخوارزميات',
      description: 'Study of fundamental data structures and algorithms',
      category: 'COMP',
      creditHours: 3,
      departmentId: mathDept.id,
      programId: csProgram.id,
      semester: 'Fall',
      academicYear: '2024-2025'
    }
  });

  const cs301 = await prisma.course.upsert({
    where: { code: 'CS301' },
    update: {},
    create: {
      code: 'CS301',
      name: 'Database Systems',
      nameAr: 'نظم قواعد البيانات',
      description: 'Introduction to database design and SQL',
      category: 'COMP',
      creditHours: 3,
      departmentId: mathDept.id,
      programId: csProgram.id,
      semester: 'Fall',
      academicYear: '2024-2025'
    }
  });

  const math101 = await prisma.course.upsert({
    where: { code: 'MATH101' },
    update: {},
    create: {
      code: 'MATH101',
      name: 'Calculus I',
      nameAr: 'التفاضل والتكامل ١',
      description: 'Introduction to differential calculus',
      category: 'MATH',
      creditHours: 4,
      departmentId: mathDept.id,
      semester: 'Fall',
      academicYear: '2024-2025'
    }
  });

  const stat201 = await prisma.course.upsert({
    where: { code: 'STAT201' },
    update: {},
    create: {
      code: 'STAT201',
      name: 'Probability Theory',
      nameAr: 'نظرية الاحتمالات',
      description: 'Introduction to probability and random variables',
      category: 'MATH',
      creditHours: 3,
      departmentId: mathDept.id,
      programId: statsProgram.id,
      semester: 'Fall',
      academicYear: '2024-2025'
    }
  });

  const cs402 = await prisma.course.upsert({
    where: { code: 'CS402' },
    update: {},
    create: {
      code: 'CS402',
      name: 'Mobile Application Development',
      nameAr: 'تطوير تطبيقات الموبايل',
      description: 'Mobile app development using Flutter',
      category: 'COMP',
      creditHours: 3,
      departmentId: mathDept.id,
      programId: csProgram.id,
      semester: 'Fall',
      academicYear: '2024-2025'
    }
  });

  console.log('✅ Courses created');

  // ============ ASSIGN INSTRUCTORS TO COURSES ============
  console.log('👨‍🏫 Assigning instructors to courses...');

  await prisma.courseInstructor.upsert({
    where: { userId_courseId: { userId: drAhmed.id, courseId: cs101.id } },
    update: {},
    create: { userId: drAhmed.id, courseId: cs101.id, isPrimary: true }
  });

  await prisma.courseInstructor.upsert({
    where: { userId_courseId: { userId: drAhmed.id, courseId: cs201.id } },
    update: {},
    create: { userId: drAhmed.id, courseId: cs201.id, isPrimary: true }
  });

  await prisma.courseInstructor.upsert({
    where: { userId_courseId: { userId: drMohamed.id, courseId: cs301.id } },
    update: {},
    create: { userId: drMohamed.id, courseId: cs301.id, isPrimary: true }
  });

  await prisma.courseInstructor.upsert({
    where: { userId_courseId: { userId: drMohamed.id, courseId: math101.id } },
    update: {},
    create: { userId: drMohamed.id, courseId: math101.id, isPrimary: true }
  });

  await prisma.courseInstructor.upsert({
    where: { userId_courseId: { userId: drAhmed.id, courseId: stat201.id } },
    update: {},
    create: { userId: drAhmed.id, courseId: stat201.id, isPrimary: true }
  });

  await prisma.courseInstructor.upsert({
    where: { userId_courseId: { userId: drAhmed.id, courseId: cs402.id } },
    update: {},
    create: { userId: drAhmed.id, courseId: cs402.id, isPrimary: true }
  });

  console.log('✅ Instructors assigned to courses');

  // ============ ENROLL STUDENTS ============
  console.log('📝 Enrolling students...');

  await prisma.enrollment.upsert({
    where: { userId_courseId: { userId: student1.id, courseId: cs101.id } },
    update: {},
    create: { userId: student1.id, courseId: cs101.id }
  });

  await prisma.enrollment.upsert({
    where: { userId_courseId: { userId: student1.id, courseId: cs201.id } },
    update: {},
    create: { userId: student1.id, courseId: cs201.id }
  });

  await prisma.enrollment.upsert({
    where: { userId_courseId: { userId: student1.id, courseId: math101.id } },
    update: {},
    create: { userId: student1.id, courseId: math101.id }
  });

  await prisma.enrollment.upsert({
    where: { userId_courseId: { userId: student2.id, courseId: cs101.id } },
    update: {},
    create: { userId: student2.id, courseId: cs101.id }
  });

  await prisma.enrollment.upsert({
    where: { userId_courseId: { userId: student2.id, courseId: cs301.id } },
    update: {},
    create: { userId: student2.id, courseId: cs301.id }
  });

  await prisma.enrollment.upsert({
    where: { userId_courseId: { userId: student3.id, courseId: stat201.id } },
    update: {},
    create: { userId: student3.id, courseId: stat201.id }
  });

  await prisma.enrollment.upsert({
    where: { userId_courseId: { userId: student3.id, courseId: math101.id } },
    update: {},
    create: { userId: student3.id, courseId: math101.id }
  });

  console.log('✅ Students enrolled');

  // ============ ADD COURSE SCHEDULES ============
  console.log('📅 Adding course schedules...');

  const schedules = [
    { courseId: cs101.id, dayOfWeek: 'SUNDAY', startTime: '09:00', endTime: '10:30', location: 'Building A', room: 'Room 101' },
    { courseId: cs101.id, dayOfWeek: 'TUESDAY', startTime: '09:00', endTime: '10:30', location: 'Building A', room: 'Room 101' },
    { courseId: cs201.id, dayOfWeek: 'SUNDAY', startTime: '11:00', endTime: '12:30', location: 'Building A', room: 'Room 201' },
    { courseId: cs201.id, dayOfWeek: 'WEDNESDAY', startTime: '11:00', endTime: '12:30', location: 'Building A', room: 'Room 201' },
    { courseId: cs301.id, dayOfWeek: 'MONDAY', startTime: '09:00', endTime: '10:30', location: 'Lab Building', room: 'Lab 301' },
    { courseId: cs301.id, dayOfWeek: 'THURSDAY', startTime: '09:00', endTime: '10:30', location: 'Lab Building', room: 'Lab 301' },
    { courseId: math101.id, dayOfWeek: 'MONDAY', startTime: '14:00', endTime: '15:30', location: 'Building B', room: 'Room 102' },
    { courseId: math101.id, dayOfWeek: 'WEDNESDAY', startTime: '14:00', endTime: '15:30', location: 'Building B', room: 'Room 102' },
    { courseId: stat201.id, dayOfWeek: 'TUESDAY', startTime: '14:00', endTime: '15:30', location: 'Building B', room: 'Room 105' },
    { courseId: cs402.id, dayOfWeek: 'THURSDAY', startTime: '14:00', endTime: '16:00', location: 'Lab Building', room: 'Mobile Lab' }
  ];

  for (const schedule of schedules) {
    await prisma.courseSchedule.create({ data: schedule });
  }

  console.log('✅ Course schedules added');

  // ============ ADD SAMPLE CONTENT ============
  console.log('📄 Adding sample content...');

  await prisma.courseContent.createMany({
    data: [
      {
        courseId: cs101.id,
        title: 'Week 1: Introduction to Python',
        description: 'Setting up Python, writing your first program, basic syntax',
        contentType: 'LECTURE',
        weekNumber: 1,
        orderIndex: 1,
        createdById: drAhmed.id
      },
      {
        courseId: cs101.id,
        title: 'Week 2: Variables and Data Types',
        description: 'Strings, numbers, booleans, type conversion',
        contentType: 'LECTURE',
        weekNumber: 2,
        orderIndex: 1,
        createdById: drAhmed.id
      },
      {
        courseId: cs201.id,
        title: 'Week 1: Arrays and Big O',
        description: 'Arrays, complexity analysis, Big O notation',
        contentType: 'LECTURE',
        weekNumber: 1,
        orderIndex: 1,
        createdById: drAhmed.id
      },
      {
        courseId: cs301.id,
        title: 'Week 1: Introduction to Databases',
        description: 'What is a database, DBMS, relational model',
        contentType: 'LECTURE',
        weekNumber: 1,
        orderIndex: 1,
        createdById: drMohamed.id
      }
    ],
    skipDuplicates: true
  });

  console.log('✅ Content added');

  // ============ CREATE SAMPLE TASKS ============
  console.log('📋 Creating tasks...');

  const nextWeek = new Date();
  nextWeek.setDate(nextWeek.getDate() + 7);

  const twoWeeks = new Date();
  twoWeeks.setDate(twoWeeks.getDate() + 14);

  const task1 = await prisma.task.create({
    data: {
      title: 'Assignment 1: Hello World',
      description: 'Write a Python program that prints your name and student ID',
      taskType: 'ASSIGNMENT',
      priority: 'MEDIUM',
      dueDate: nextWeek,
      maxPoints: 50,
      courseId: cs101.id,
      createdById: drAhmed.id
    }
  });

  await prisma.task.create({
    data: {
      title: 'Midterm Exam',
      description: 'Covers weeks 1-7: Variables, Control Flow, Functions, Lists',
      taskType: 'EXAM',
      priority: 'HIGH',
      dueDate: twoWeeks,
      startDate: twoWeeks,
      maxPoints: 100,
      courseId: cs101.id,
      createdById: drAhmed.id
    }
  });

  await prisma.task.create({
    data: {
      title: 'Lab Exercise: Linked Lists',
      description: 'Implement a singly linked list with insert, delete, and search',
      taskType: 'LAB',
      priority: 'MEDIUM',
      dueDate: nextWeek,
      maxPoints: 30,
      courseId: cs201.id,
      createdById: drAhmed.id
    }
  });

  // Create task submissions for students
  await prisma.taskSubmission.create({
    data: { taskId: task1.id, studentId: student1.id, status: 'PENDING' }
  });
  await prisma.taskSubmission.create({
    data: { taskId: task1.id, studentId: student2.id, status: 'PENDING' }
  });

  console.log('✅ Tasks created');

  // ============ CREATE ANNOUNCEMENTS ============
  console.log('📢 Creating announcements...');

  await prisma.announcement.createMany({
    data: [
      {
        title: 'Welcome to Fall 2024!',
        message: 'Welcome to the new semester. Check your schedules and course materials.',
        type: 'GENERAL',
        isPinned: true,
        createdById: admin.id
      },
      {
        title: 'Office Hours Update',
        message: 'My office hours are now Sundays and Tuesdays 2-4 PM',
        type: 'GENERAL',
        courseId: cs101.id,
        createdById: drAhmed.id
      },
      {
        title: 'Lab Assignment Due',
        message: 'Remember to submit your lab assignment by next Thursday',
        type: 'ASSIGNMENT',
        courseId: cs201.id,
        createdById: drAhmed.id
      }
    ],
    skipDuplicates: true
  });

  console.log('✅ Announcements created');

  // ============ SUMMARY ============
  console.log('\n' + '═'.repeat(60));
  console.log('✨ DATABASE SEEDING COMPLETED SUCCESSFULLY!');
  console.log('═'.repeat(60));
  console.log('\n📊 Summary:');
  console.log(`   • ${await prisma.faculty.count()} Faculty`);
  console.log(`   • ${await prisma.department.count()} Departments`);
  console.log(`   • ${await prisma.program.count()} Programs (Specializations)`);
  console.log(`   • ${await prisma.user.count()} Users`);
  console.log(`   • ${await prisma.course.count()} Courses`);
  console.log(`   • ${await prisma.enrollment.count()} Enrollments`);
  console.log(`   • ${await prisma.task.count()} Tasks`);
  
  console.log('\n🔐 TEST ACCOUNTS:');
  console.log('─'.repeat(60));
  console.log('│ Role      │ Email                    │ Password      │');
  console.log('─'.repeat(60));
  console.log('│ Admin     │ admin@college.edu        │ admin123      │');
  console.log('│ Professor │ dr.ahmed@college.edu     │ professor123  │');
  console.log('│ Professor │ dr.mohamed@college.edu   │ professor123  │');
  console.log('│ Professor │ dr.sara@college.edu      │ professor123  │');
  console.log('│ Professor │ dr.khalid@college.edu    │ professor123  │');
  console.log('│ Student   │ student@college.edu      │ student123    │');
  console.log('│ Student   │ mona@college.edu         │ student123    │');
  console.log('│ Student   │ omar@college.edu         │ student123    │');
  console.log('─'.repeat(60));
  console.log('\n📁 Structure:');
  console.log('   Faculty of Science');
  console.log('   ├── Mathematics Department');
  console.log('   │   ├── Computer Science Program (Dr. Ahmed, Dr. Mohamed)');
  console.log('   │   ├── Statistics Program (Dr. Ahmed)');
  console.log('   │   └── Pure Mathematics Program (Dr. Mohamed)');
  console.log('   ├── Biology Department');
  console.log('   │   ├── Zoology Program (Dr. Sara)');
  console.log('   │   ├── Botany Program');
  console.log('   │   └── Microbiology Program (Dr. Sara)');
  console.log('   ├── Chemistry Department');
  console.log('   │   ├── Applied Chemistry Program (Dr. Khalid)');
  console.log('   │   └── Biochemistry Program (Dr. Khalid)');
  console.log('   └── Physics Department\n');
}

main()
  .catch((e) => {
    console.error('❌ Seed error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
