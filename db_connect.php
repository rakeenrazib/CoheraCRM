<?php
// api/db_connect.php

$servername = "localhost"; // Or your database host
$username = "root";        // Your database username
$password = "your_db_password"; // Your database password
$dbname = "cohera_db";     // The name of your database

// Create connection using MySQLi
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    // Stop the script and report the error
    die("Connection failed: " . $conn->connect_error);
}

// Set charset to utf8mb4 for full character support
$conn->set_charset("utf8mb4");

?>