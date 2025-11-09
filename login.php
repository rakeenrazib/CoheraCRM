<?php
// api/login.php

// 1. Start the session
// This MUST be called before any HTML output
session_start();

// 2. Include the database connection
include 'db_connect.php';

// 3. Get data from the frontend
$input = json_decode(file_get_contents('php://input'), true);
$email = $input['email'];
$password = $input['password'];

if (empty($email) || empty($password)) {
    http_response_code(400);
    echo json_encode(['message' => 'Email and password are required.']);
    exit;
}

// 4. Find the user in the database
// Use a prepared statement to prevent SQL injection
$stmt = $conn->prepare("SELECT user_id, org_id, password_hash, role, full_name FROM users WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 1) {
    // User found, fetch their data
    $user = $result->fetch_assoc();
    
    // 5. Verify the hashed password
    if (password_verify($password, $user['password_hash'])) {
        
        // 6. Password is correct! Store user data in the session.
        // This is what "logs them in".
        $_SESSION['user_id'] = $user['user_id'];
        $_SESSION['org_id'] = $user['org_id'];
        $_SESSION['role'] = $user['role'];
        $_SESSION['full_name'] = $user['full_name'];
        
        // Send a success response
        http_response_code(200);
        echo json_encode(['message' => 'Login successful.']);
        
    } else {
        // Invalid password
        http_response_code(401); // Unauthorized
        echo json_encode(['message' => 'Invalid email or password.']);
    }
    
} else {
    // No user found with that email
    http_response_code(401); // Unauthorized
    echo json_encode(['message' => 'Invalid email or password.']);
}

$stmt->close();
$conn->close();

?>