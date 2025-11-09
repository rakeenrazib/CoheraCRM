<?php
// api/check_auth.php

// Start the session to access session variables
session_start();

// Check if the user is "logged in" (i.e., if session variables are set)
if (!isset($_SESSION['user_id']) || !isset($_SESSION['org_id'])) {
    
    // User is not logged in.
    // Send an unauthorized error and stop the script.
    http_response_code(401); // Unauthorized
    echo json_encode(['message' => 'You are not logged in.']);
    
    // We stop the script that included this file.
    exit;
}

// If we are here, the user is authenticated.
// We can now make the session variables available to the script that included this one.
$user_id = $_SESSION['user_id'];
$org_id = $_SESSION['org_id'];
$user_role = $_SESSION['role'];
$user_full_name = $_SESSION['full_name'];

?>