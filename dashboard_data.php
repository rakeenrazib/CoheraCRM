<?php
// api/dashboard_data.php

// 1. Check if user is logged in.
// This script will stop here if they aren't.
// CORRECTED PATH: Removed 'api/' prefix since this file is already in the api folder.
include 'check_auth.php'; 
// $org_id and $user_id are now available from check_auth.php

// 2. Include the database connection
// CORRECTED PATH: Removed 'api/' prefix.
include 'db_connect.php'; 

// 3. Prepare the final data array
// This will look JUST like your mockData object
$dashboardData = [];

// 4. Fetch data based on the user's role
// The logic from your JS 'mockData' is now here in PHP.
if ($user_role === 'admin') {
    // --- ADMIN DATA ---
    $dashboardData = [
        'name' => $user_full_name,
        'role' => 'Company Administrator',
        'avatarUrl' => 'https://placehold.co/100x100/c7d2fe/312e81?text=MM', // You can store this in the DB later
        'stats' => [],
        'quickActions' => [
            // Hardcode these for now, same as mockData
            ['name' => 'Add New User', 'icon' => '...svg...'],
            ['name' => 'Add New Client', 'icon' => '...svg...']
            // ... etc
        ],
        'activityFeed' => [], // You would query the 'activities' table
        'todayAgenda' => [],  // You would query the 'meetings' table
        'issues' => []        // You would query the 'issues' table
    ];
    
    // Example: Fetch Admin Stats
    // Stat 1: Total Company Clients
    $stmt = $conn->prepare("SELECT COUNT(*) as count FROM clients WHERE org_id = ?");
    $stmt->bind_param("i", $org_id);
    $stmt->execute();
    $count = $stmt->get_result()->fetch_assoc()['count'];
    $dashboardData['stats'][] = ['name' => 'Total Company Clients', 'value' => $count, 'icon' => '...svg...'];
    
    // Stat 2: Total Open Issues
    $stmt = $conn->prepare("SELECT COUNT(*) as count FROM issues WHERE org_id = ? AND status = 'Open'");
    $stmt->bind_param("i", $org_id);
    $stmt->execute();
    $count = $stmt->get_result()->fetch_assoc()['count'];
    $dashboardData['stats'][] = ['name' => 'Total Open Issues', 'value' => $count, 'icon' => '...svg...'];
    
    // ... (fetch other stats, agenda, issues for admin) ...

} else {
    // --- USER DATA ---
    $dashboardData = [
        'name' => $user_full_name,
        'role' => 'Sales & Support Team',
        'avatarUrl' => 'https://placehold.co/100x100/bbf7d0/15803d?text=RR',
        'stats' => [],
        'quickActions' => [ /* User quick actions... */ ],
        'activityFeed' => [],
        'todayAgenda' => [],
        'issues' => []
    ];
    
    // Example: Fetch User Stats
    // Stat 1: My Clients (clients assigned to this user)
    $stmt = $conn->prepare("SELECT COUNT(*) as count FROM clients WHERE org_id = ? AND assigned_to_user_id = ?");
    $stmt->bind_param("ii", $org_id, $user_id);
    $stmt->execute();
    $count = $stmt->get_result()->fetch_assoc()['count'];
    $dashboardData['stats'][] = ['name' => 'My Clients', 'value' => $count, 'icon' => '...svg...'];

    // Stat 2: My Open Issues
    $stmt = $conn->prepare("SELECT COUNT(*) as count FROM issues WHERE org_id = ? AND assigned_to_user_id = ? AND status = 'Open'");
    $stmt->bind_param("ii", $org_id, $user_id);
    $stmt->execute();
    $count = $stmt->get_result()->fetch_assoc()['count'];
    $dashboardData['stats'][] = ['name' => 'My Open Issues', 'value' => $count, 'icon' => '...svg...'];
    
    // ... (fetch other stats, agenda, issues for this user) ...
}


// 5. Send the final JSON data back to the frontend
http_response_code(200);
header('Content-Type: application/json'); // Tell the browser this is JSON
echo json_encode($dashboardData);

// Close statement if it was created
if (isset($stmt)) {
    $stmt->close();
}
$conn->close();
?>