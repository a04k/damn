const mysql = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    ssl: { rejectUnauthorized: false }
});

// Comprehensive courses for Faculty of Science
const courses = [
    // ==================== COMPUTER SCIENCE (COMP) ====================
    // Level 1
    { id: 'COMP101', code: 'COMP101', name: 'Introduction to Computer Science', category: 'comp', creditHours: 3, level: 1, professors: ['Dr. Ahmed Hassan'], description: 'Fundamentals of computing, history of computers, and basic concepts.' },
    { id: 'COMP102', code: 'COMP102', name: 'Programming Fundamentals', category: 'comp', creditHours: 4, level: 1, professors: ['Dr. Sara Mohamed'], description: 'Introduction to programming using C++, variables, loops, functions.' },
    { id: 'COMP103', code: 'COMP103', name: 'Discrete Mathematics', category: 'comp', creditHours: 3, level: 1, professors: ['Dr. Khaled Ali'], description: 'Logic, sets, relations, functions, and graph theory basics.' },
    { id: 'COMP104', code: 'COMP104', name: 'Computer Skills', category: 'comp', creditHours: 2, level: 1, professors: ['Dr. Mona Ibrahim'], description: 'Office applications, internet basics, and computer literacy.' },

    // Level 2
    { id: 'COMP201', code: 'COMP201', name: 'Data Structures', category: 'comp', creditHours: 4, level: 2, professors: ['Dr. Ahmed Hassan'], description: 'Arrays, linked lists, stacks, queues, trees, and graphs.' },
    { id: 'COMP202', code: 'COMP202', name: 'Object Oriented Programming', category: 'comp', creditHours: 3, level: 2, professors: ['Dr. Sara Mohamed'], description: 'Classes, objects, inheritance, polymorphism using Java.' },
    { id: 'COMP203', code: 'COMP203', name: 'Computer Architecture', category: 'comp', creditHours: 3, level: 2, professors: ['Dr. Youssef Mahmoud'], description: 'CPU design, memory hierarchy, instruction sets.' },
    { id: 'COMP204', code: 'COMP204', name: 'Database Systems I', category: 'comp', creditHours: 3, level: 2, professors: ['Dr. Fatma Nasser'], description: 'Relational databases, SQL, ER diagrams, normalization.' },
    { id: 'COMP205', code: 'COMP205', name: 'Logic Design', category: 'comp', creditHours: 3, level: 2, professors: ['Dr. Khaled Ali'], description: 'Boolean algebra, combinational and sequential circuits.' },

    // Level 3
    { id: 'COMP301', code: 'COMP301', name: 'Algorithms', category: 'comp', creditHours: 3, level: 3, professors: ['Dr. Ahmed Hassan'], description: 'Algorithm design, analysis, sorting, searching, dynamic programming.' },
    { id: 'COMP302', code: 'COMP302', name: 'Operating Systems', category: 'comp', creditHours: 3, level: 3, professors: ['Dr. Youssef Mahmoud'], description: 'Process management, memory management, file systems, scheduling.' },
    { id: 'COMP303', code: 'COMP303', name: 'Computer Networks', category: 'comp', creditHours: 3, level: 3, professors: ['Dr. Mohamed Samir'], description: 'OSI model, TCP/IP, routing, network protocols.' },
    { id: 'COMP304', code: 'COMP304', name: 'Software Engineering', category: 'comp', creditHours: 3, level: 3, professors: ['Dr. Sara Mohamed'], description: 'SDLC, requirements, design patterns, testing, agile methods.' },
    { id: 'COMP305', code: 'COMP305', name: 'Database Systems II', category: 'comp', creditHours: 3, level: 3, professors: ['Dr. Fatma Nasser'], description: 'Advanced SQL, transactions, indexing, query optimization.' },
    { id: 'COMP306', code: 'COMP306', name: 'Web Development', category: 'comp', creditHours: 3, level: 3, professors: ['Dr. Mona Ibrahim'], description: 'HTML, CSS, JavaScript, frontend and backend basics.' },

    // Level 4
    { id: 'COMP401', code: 'COMP401', name: 'Artificial Intelligence', category: 'comp', creditHours: 3, level: 4, professors: ['Dr. Ahmed Hassan'], description: 'Search algorithms, knowledge representation, machine learning basics.' },
    { id: 'COMP402', code: 'COMP402', name: 'Machine Learning', category: 'comp', creditHours: 3, level: 4, professors: ['Dr. Sara Mohamed'], description: 'Supervised and unsupervised learning, neural networks, deep learning.' },
    { id: 'COMP403', code: 'COMP403', name: 'Computer Security', category: 'comp', creditHours: 3, level: 4, professors: ['Dr. Mohamed Samir'], description: 'Cryptography, network security, authentication, ethical hacking.' },
    { id: 'COMP404', code: 'COMP404', name: 'Mobile Application Development', category: 'comp', creditHours: 3, level: 4, professors: ['Dr. Mona Ibrahim'], description: 'Android and iOS development, Flutter, React Native.' },
    { id: 'COMP405', code: 'COMP405', name: 'Graduation Project', category: 'comp', creditHours: 6, level: 4, professors: ['Department Supervisors'], description: 'Final year capstone project demonstrating comprehensive skills.' },
    { id: 'COMP406', code: 'COMP406', name: 'Cloud Computing', category: 'comp', creditHours: 3, level: 4, professors: ['Dr. Youssef Mahmoud'], description: 'AWS, Azure, cloud architecture, containerization, DevOps.' },

    // ==================== MATHEMATICS (MATH) ====================
    // Level 1
    { id: 'MATH101', code: 'MATH101', name: 'Calculus I', category: 'math', creditHours: 4, level: 1, professors: ['Dr. Mahmoud Fathy'], description: 'Limits, derivatives, integrals, fundamental theorem of calculus.' },
    { id: 'MATH102', code: 'MATH102', name: 'Calculus II', category: 'math', creditHours: 4, level: 1, professors: ['Dr. Mahmoud Fathy'], description: 'Techniques of integration, sequences, series, parametric equations.' },
    { id: 'MATH103', code: 'MATH103', name: 'Linear Algebra I', category: 'math', creditHours: 3, level: 1, professors: ['Dr. Heba Ahmed'], description: 'Vectors, matrices, determinants, systems of linear equations.' },
    { id: 'MATH104', code: 'MATH104', name: 'Geometry', category: 'math', creditHours: 3, level: 1, professors: ['Dr. Nadia Kamal'], description: 'Euclidean geometry, coordinate geometry, transformations.' },

    // Level 2
    { id: 'MATH201', code: 'MATH201', name: 'Calculus III', category: 'math', creditHours: 4, level: 2, professors: ['Dr. Mahmoud Fathy'], description: 'Multivariable calculus, partial derivatives, multiple integrals.' },
    { id: 'MATH202', code: 'MATH202', name: 'Linear Algebra II', category: 'math', creditHours: 3, level: 2, professors: ['Dr. Heba Ahmed'], description: 'Vector spaces, linear transformations, eigenvalues, eigenvectors.' },
    { id: 'MATH203', code: 'MATH203', name: 'Differential Equations', category: 'math', creditHours: 3, level: 2, professors: ['Dr. Ali Mostafa'], description: 'First and second order ODEs, Laplace transforms, systems of ODEs.' },
    { id: 'MATH204', code: 'MATH204', name: 'Number Theory', category: 'math', creditHours: 3, level: 2, professors: ['Dr. Nadia Kamal'], description: 'Divisibility, prime numbers, congruences, cryptographic applications.' },

    // Level 3
    { id: 'MATH301', code: 'MATH301', name: 'Real Analysis', category: 'math', creditHours: 3, level: 3, professors: ['Dr. Mahmoud Fathy'], description: 'Rigorous treatment of real numbers, sequences, series, continuity.' },
    { id: 'MATH302', code: 'MATH302', name: 'Complex Analysis', category: 'math', creditHours: 3, level: 3, professors: ['Dr. Heba Ahmed'], description: 'Complex numbers, analytic functions, contour integration, residues.' },
    { id: 'MATH303', code: 'MATH303', name: 'Abstract Algebra', category: 'math', creditHours: 3, level: 3, professors: ['Dr. Ali Mostafa'], description: 'Groups, rings, fields, homomorphisms, quotient structures.' },
    { id: 'MATH304', code: 'MATH304', name: 'Numerical Analysis', category: 'math', creditHours: 3, level: 3, professors: ['Dr. Nadia Kamal'], description: 'Root finding, interpolation, numerical integration, error analysis.' },

    // Level 4
    { id: 'MATH401', code: 'MATH401', name: 'Topology', category: 'math', creditHours: 3, level: 4, professors: ['Dr. Mahmoud Fathy'], description: 'Topological spaces, continuity, compactness, connectedness.' },
    { id: 'MATH402', code: 'MATH402', name: 'Functional Analysis', category: 'math', creditHours: 3, level: 4, professors: ['Dr. Heba Ahmed'], description: 'Banach spaces, Hilbert spaces, operators, spectral theory.' },
    { id: 'MATH403', code: 'MATH403', name: 'Partial Differential Equations', category: 'math', creditHours: 3, level: 4, professors: ['Dr. Ali Mostafa'], description: 'Heat, wave, and Laplace equations, separation of variables.' },

    // ==================== STATISTICS (STAT) ====================
    // Level 1
    { id: 'STAT101', code: 'STAT101', name: 'Introduction to Statistics', category: 'math', creditHours: 3, level: 1, professors: ['Dr. Amira Sayed'], description: 'Descriptive statistics, probability basics, distributions.' },
    { id: 'STAT102', code: 'STAT102', name: 'Probability Theory I', category: 'math', creditHours: 3, level: 1, professors: ['Dr. Omar Farouk'], description: 'Sample spaces, random variables, expectation, variance.' },

    // Level 2
    { id: 'STAT201', code: 'STAT201', name: 'Probability Theory II', category: 'math', creditHours: 3, level: 2, professors: ['Dr. Omar Farouk'], description: 'Joint distributions, moment generating functions, limit theorems.' },
    { id: 'STAT202', code: 'STAT202', name: 'Statistical Inference', category: 'math', creditHours: 3, level: 2, professors: ['Dr. Amira Sayed'], description: 'Estimation, hypothesis testing, confidence intervals.' },

    // Level 3
    { id: 'STAT301', code: 'STAT301', name: 'Regression Analysis', category: 'math', creditHours: 3, level: 3, professors: ['Dr. Amira Sayed'], description: 'Linear regression, multiple regression, model diagnostics.' },
    { id: 'STAT302', code: 'STAT302', name: 'Time Series Analysis', category: 'math', creditHours: 3, level: 3, professors: ['Dr. Omar Farouk'], description: 'ARIMA models, forecasting, seasonal adjustments.' },

    // Level 4
    { id: 'STAT401', code: 'STAT401', name: 'Multivariate Statistics', category: 'math', creditHours: 3, level: 4, professors: ['Dr. Amira Sayed'], description: 'PCA, factor analysis, clustering, discriminant analysis.' },
    { id: 'STAT402', code: 'STAT402', name: 'Bayesian Statistics', category: 'math', creditHours: 3, level: 4, professors: ['Dr. Omar Farouk'], description: 'Bayesian inference, priors, posteriors, MCMC methods.' },

    // ==================== PHYSICS (PHYS) ====================
    // Level 1
    { id: 'PHYS101', code: 'PHYS101', name: 'General Physics I', category: 'phys', creditHours: 4, level: 1, professors: ['Dr. Hassan Mostafa'], description: 'Mechanics, Newton laws, work, energy, momentum.' },
    { id: 'PHYS102', code: 'PHYS102', name: 'General Physics II', category: 'phys', creditHours: 4, level: 1, professors: ['Dr. Mariam Ali'], description: 'Electricity, magnetism, circuits, electromagnetic waves.' },
    { id: 'PHYS103', code: 'PHYS103', name: 'Physics Laboratory I', category: 'phys', creditHours: 2, level: 1, professors: ['Dr. Hassan Mostafa'], description: 'Hands-on experiments in mechanics and measurements.' },

    // Level 2
    { id: 'PHYS201', code: 'PHYS201', name: 'Classical Mechanics', category: 'phys', creditHours: 3, level: 2, professors: ['Dr. Hassan Mostafa'], description: 'Lagrangian mechanics, Hamiltonian mechanics, central forces.' },
    { id: 'PHYS202', code: 'PHYS202', name: 'Thermodynamics', category: 'phys', creditHours: 3, level: 2, professors: ['Dr. Mariam Ali'], description: 'Laws of thermodynamics, entropy, heat engines, refrigeration.' },
    { id: 'PHYS203', code: 'PHYS203', name: 'Waves and Optics', category: 'phys', creditHours: 3, level: 2, professors: ['Dr. Tarek Salah'], description: 'Wave motion, interference, diffraction, polarization.' },
    { id: 'PHYS204', code: 'PHYS204', name: 'Electronics I', category: 'phys', creditHours: 3, level: 2, professors: ['Dr. Mariam Ali'], description: 'Semiconductors, diodes, transistors, amplifiers.' },

    // Level 3
    { id: 'PHYS301', code: 'PHYS301', name: 'Quantum Mechanics I', category: 'phys', creditHours: 3, level: 3, professors: ['Dr. Hassan Mostafa'], description: 'Wave-particle duality, Schrodinger equation, quantum states.' },
    { id: 'PHYS302', code: 'PHYS302', name: 'Electromagnetism', category: 'phys', creditHours: 3, level: 3, professors: ['Dr. Tarek Salah'], description: 'Maxwell equations, electromagnetic radiation, waveguides.' },
    { id: 'PHYS303', code: 'PHYS303', name: 'Statistical Mechanics', category: 'phys', creditHours: 3, level: 3, professors: ['Dr. Mariam Ali'], description: 'Ensembles, partition functions, quantum statistics.' },
    { id: 'PHYS304', code: 'PHYS304', name: 'Solid State Physics', category: 'phys', creditHours: 3, level: 3, professors: ['Dr. Tarek Salah'], description: 'Crystal structure, band theory, semiconductors.' },

    // Level 4
    { id: 'PHYS401', code: 'PHYS401', name: 'Quantum Mechanics II', category: 'phys', creditHours: 3, level: 4, professors: ['Dr. Hassan Mostafa'], description: 'Angular momentum, spin, perturbation theory, scattering.' },
    { id: 'PHYS402', code: 'PHYS402', name: 'Nuclear Physics', category: 'phys', creditHours: 3, level: 4, professors: ['Dr. Mariam Ali'], description: 'Nuclear structure, radioactivity, reactions, applications.' },
    { id: 'PHYS403', code: 'PHYS403', name: 'Atomic and Molecular Physics', category: 'phys', creditHours: 3, level: 4, professors: ['Dr. Tarek Salah'], description: 'Atomic spectra, molecular bonding, spectroscopy.' },

    // ==================== CHEMISTRY (CHEM) ====================
    // Level 1
    { id: 'CHEM101', code: 'CHEM101', name: 'General Chemistry I', category: 'chem', creditHours: 4, level: 1, professors: ['Dr. Laila Mahmoud'], description: 'Atomic structure, bonding, stoichiometry, states of matter.' },
    { id: 'CHEM102', code: 'CHEM102', name: 'General Chemistry II', category: 'chem', creditHours: 4, level: 1, professors: ['Dr. Sherif Adel'], description: 'Chemical equilibrium, acids/bases, electrochemistry.' },
    { id: 'CHEM103', code: 'CHEM103', name: 'Chemistry Laboratory I', category: 'chem', creditHours: 2, level: 1, professors: ['Dr. Laila Mahmoud'], description: 'Basic laboratory techniques and experiments.' },

    // Level 2
    { id: 'CHEM201', code: 'CHEM201', name: 'Organic Chemistry I', category: 'chem', creditHours: 3, level: 2, professors: ['Dr. Sherif Adel'], description: 'Hydrocarbons, functional groups, nomenclature, reactions.' },
    { id: 'CHEM202', code: 'CHEM202', name: 'Inorganic Chemistry', category: 'chem', creditHours: 3, level: 2, professors: ['Dr. Laila Mahmoud'], description: 'Periodic trends, coordination chemistry, transition metals.' },
    { id: 'CHEM203', code: 'CHEM203', name: 'Analytical Chemistry', category: 'chem', creditHours: 3, level: 2, professors: ['Dr. Nour El-Din'], description: 'Quantitative analysis, titrations, spectroscopy basics.' },
    { id: 'CHEM204', code: 'CHEM204', name: 'Physical Chemistry I', category: 'chem', creditHours: 3, level: 2, professors: ['Dr. Sherif Adel'], description: 'Thermodynamics, kinetics, phase equilibria.' },

    // Level 3
    { id: 'CHEM301', code: 'CHEM301', name: 'Organic Chemistry II', category: 'chem', creditHours: 3, level: 3, professors: ['Dr. Sherif Adel'], description: 'Reaction mechanisms, synthesis, stereochemistry.' },
    { id: 'CHEM302', code: 'CHEM302', name: 'Physical Chemistry II', category: 'chem', creditHours: 3, level: 3, professors: ['Dr. Laila Mahmoud'], description: 'Quantum chemistry, spectroscopy, statistical thermodynamics.' },
    { id: 'CHEM303', code: 'CHEM303', name: 'Biochemistry', category: 'chem', creditHours: 3, level: 3, professors: ['Dr. Nour El-Din'], description: 'Proteins, enzymes, metabolism, nucleic acids.' },
    { id: 'CHEM304', code: 'CHEM304', name: 'Instrumental Analysis', category: 'chem', creditHours: 3, level: 3, professors: ['Dr. Nour El-Din'], description: 'NMR, mass spectrometry, chromatography, IR spectroscopy.' },

    // Level 4
    { id: 'CHEM401', code: 'CHEM401', name: 'Advanced Organic Chemistry', category: 'chem', creditHours: 3, level: 4, professors: ['Dr. Sherif Adel'], description: 'Advanced synthesis, natural products, heterocycles.' },
    { id: 'CHEM402', code: 'CHEM402', name: 'Polymer Chemistry', category: 'chem', creditHours: 3, level: 4, professors: ['Dr. Laila Mahmoud'], description: 'Polymerization, polymer properties, applications.' },
    { id: 'CHEM403', code: 'CHEM403', name: 'Environmental Chemistry', category: 'chem', creditHours: 3, level: 4, professors: ['Dr. Nour El-Din'], description: 'Pollution, water treatment, green chemistry.' },

    // ==================== BIOLOGY (BIO) - Using 'eng' category as placeholder ====================
    // Level 1
    { id: 'BIO101', code: 'BIO101', name: 'General Biology I', category: 'eng', creditHours: 4, level: 1, professors: ['Dr. Rania Hassan'], description: 'Cell biology, genetics, evolution basics.' },
    { id: 'BIO102', code: 'BIO102', name: 'General Biology II', category: 'eng', creditHours: 4, level: 1, professors: ['Dr. Karim Youssef'], description: 'Plant and animal diversity, ecology, physiology.' },

    // Level 2
    { id: 'BIO201', code: 'BIO201', name: 'Genetics', category: 'eng', creditHours: 3, level: 2, professors: ['Dr. Rania Hassan'], description: 'Mendelian genetics, molecular genetics, population genetics.' },
    { id: 'BIO202', code: 'BIO202', name: 'Microbiology', category: 'eng', creditHours: 3, level: 2, professors: ['Dr. Karim Youssef'], description: 'Bacteria, viruses, fungi, microbial ecology.' },
    { id: 'BIO203', code: 'BIO203', name: 'Plant Biology', category: 'eng', creditHours: 3, level: 2, professors: ['Dr. Rania Hassan'], description: 'Plant anatomy, physiology, reproduction.' },
    { id: 'BIO204', code: 'BIO204', name: 'Animal Biology', category: 'eng', creditHours: 3, level: 2, professors: ['Dr. Karim Youssef'], description: 'Animal systems, comparative anatomy, behavior.' },

    // Level 3
    { id: 'BIO301', code: 'BIO301', name: 'Molecular Biology', category: 'eng', creditHours: 3, level: 3, professors: ['Dr. Rania Hassan'], description: 'DNA replication, transcription, translation, gene regulation.' },
    { id: 'BIO302', code: 'BIO302', name: 'Ecology', category: 'eng', creditHours: 3, level: 3, professors: ['Dr. Karim Youssef'], description: 'Ecosystems, population dynamics, conservation biology.' },
    { id: 'BIO303', code: 'BIO303', name: 'Immunology', category: 'eng', creditHours: 3, level: 3, professors: ['Dr. Rania Hassan'], description: 'Immune system, vaccines, autoimmunity, immunotherapy.' },

    // Level 4
    { id: 'BIO401', code: 'BIO401', name: 'Biotechnology', category: 'eng', creditHours: 3, level: 4, professors: ['Dr. Rania Hassan'], description: 'Genetic engineering, cloning, PCR, applications.' },
    { id: 'BIO402', code: 'BIO402', name: 'Bioinformatics', category: 'eng', creditHours: 3, level: 4, professors: ['Dr. Karim Youssef'], description: 'Sequence analysis, databases, phylogenetics, structural biology.' },

    // ==================== GEOLOGY (GEOL) - Using 'hist' category as placeholder ====================
    // Level 1
    { id: 'GEOL101', code: 'GEOL101', name: 'Physical Geology', category: 'hist', creditHours: 3, level: 1, professors: ['Dr. Sami Othman'], description: 'Earth materials, plate tectonics, minerals, rocks.' },
    { id: 'GEOL102', code: 'GEOL102', name: 'Historical Geology', category: 'hist', creditHours: 3, level: 1, professors: ['Dr. Hana Zaki'], description: 'Earth history, fossils, geological time scale.' },

    // Level 2
    { id: 'GEOL201', code: 'GEOL201', name: 'Mineralogy', category: 'hist', creditHours: 3, level: 2, professors: ['Dr. Sami Othman'], description: 'Crystal systems, mineral properties, identification.' },
    { id: 'GEOL202', code: 'GEOL202', name: 'Petrology', category: 'hist', creditHours: 3, level: 2, professors: ['Dr. Hana Zaki'], description: 'Igneous, sedimentary, metamorphic rocks formation.' },
    { id: 'GEOL203', code: 'GEOL203', name: 'Structural Geology', category: 'hist', creditHours: 3, level: 2, professors: ['Dr. Sami Othman'], description: 'Folds, faults, stress, strain, geological maps.' },

    // Level 3
    { id: 'GEOL301', code: 'GEOL301', name: 'Paleontology', category: 'hist', creditHours: 3, level: 3, professors: ['Dr. Hana Zaki'], description: 'Fossils, evolution, biostratigraphy, paleoecology.' },
    { id: 'GEOL302', code: 'GEOL302', name: 'Sedimentology', category: 'hist', creditHours: 3, level: 3, professors: ['Dr. Sami Othman'], description: 'Sediment transport, depositional environments, stratigraphy.' },
    { id: 'GEOL303', code: 'GEOL303', name: 'Geophysics', category: 'hist', creditHours: 3, level: 3, professors: ['Dr. Hana Zaki'], description: 'Seismic, gravity, magnetic methods, Earth interior.' },

    // Level 4
    { id: 'GEOL401', code: 'GEOL401', name: 'Hydrogeology', category: 'hist', creditHours: 3, level: 4, professors: ['Dr. Sami Othman'], description: 'Groundwater, aquifers, water resources, contamination.' },
    { id: 'GEOL402', code: 'GEOL402', name: 'Economic Geology', category: 'hist', creditHours: 3, level: 4, professors: ['Dr. Hana Zaki'], description: 'Ore deposits, mining, petroleum geology.' },
    { id: 'GEOL403', code: 'GEOL403', name: 'Environmental Geology', category: 'hist', creditHours: 3, level: 4, professors: ['Dr. Sami Othman'], description: 'Natural hazards, land use, geological engineering.' },
];

async function seedCourses() {
    try {
        console.log('🌱 Starting comprehensive course seeding...');
        console.log(`📚 Total courses to seed: ${courses.length}`);

        // Clear existing courses
        await pool.execute('DELETE FROM courses');
        console.log('🧹 Cleared existing courses.');

        let successCount = 0;
        for (const course of courses) {
            try {
                await pool.execute(
                    `INSERT INTO courses 
                    (id, code, name, category, credit_hours, professors, description, schedule, content, assignments, exams) 
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                    [
                        course.id,
                        course.code,
                        course.name,
                        course.category,
                        course.creditHours,
                        JSON.stringify(course.professors),
                        course.description,
                        JSON.stringify([{ day: 'TBD', time: 'TBD', location: 'TBD' }]),
                        JSON.stringify([]),
                        JSON.stringify([]),
                        JSON.stringify([])
                    ]
                );
                successCount++;
            } catch (err) {
                console.error(`❌ Failed to insert ${course.code}:`, err.message);
            }
        }

        console.log(`\n✅ Successfully seeded ${successCount}/${courses.length} courses!`);
        console.log('\n📊 Course breakdown by category:');

        const categories = {};
        courses.forEach(c => {
            categories[c.category] = (categories[c.category] || 0) + 1;
        });
        Object.entries(categories).forEach(([cat, count]) => {
            console.log(`   ${cat.toUpperCase()}: ${count} courses`);
        });

    } catch (error) {
        console.error('❌ Error seeding courses:', error);
    } finally {
        await pool.end();
    }
}

seedCourses();
