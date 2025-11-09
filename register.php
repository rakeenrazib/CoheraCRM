<?php
// api/register.php

// 1. Include the database connection
include 'db_connect.php';

// 2. Get data from the frontend (sent as JSON)
$input = json_decode(file_get_contents('php://input'), true);

$fullName = $input['fullName'];
$companyName = $input['companyName'];
$email = $input['email'];
$password = $input['password'];

// 3. Basic Validation
if (empty($fullName) || empty($companyName) || empty($email) || empty($password)) {
    // Send an error response and stop the script
    http_response_code(400); // Bad Request
    echo json_encode(['message' => 'All fields are required.']);
    exit;
}

// 4. Secure the Password
// NEVER store plain-text passwords. Always hash them.
$password_hash = password_hash($password, PASSWORD_DEFAULT);

// 5. Use Prepared Statements to prevent SQL Injection
// We must do this in a transaction, as two tables are involved.

$conn->begin_transaction();

try {
    // Query 1: Create the organization
    $stmt1 = $conn->prepare("INSERT INTO organizations (company_name) VALUES (?)");
    $stmt1->bind_param("s", $companyName);
    $stmt1->execute();
    
    // Get the new org_id that was just created
    $new_org_id = $conn->insert_id;
    
    // Query 2: Create the user (as 'admin' of that org)
    $stmt2 = $conn->prepare("INSERT INTO users (org_id, full_name, email, password_hash, role) VALUES (?, ?, ?, ?, 'admin')");
    $stmt2->bind_param("isss", $new_org_id, $fullName, $email, $password_hash);
    $stmt2->execute();
    
    // If both queries worked, commit the changes
    $conn->commit();
    
    // Send a success response
    http_response_code(201); // Created
    echo json_encode(['message' => 'Account created successfully.']);

} catch (mysqli_sql_exception $exception) {
    // If anything failed, roll back the changes
    $conn->rollback();
    
    // Send an error (e.g., if email is not unique)
    http_response_code(500); // Internal Server Error
    echo json_encode(['message' => 'Could not create account: ' . $exception->getMessage()]);
}

// 6. Close statements and connection
$stmt1->close();
$stmt2->close();
$conn->close();

?>