<?php
date_default_timezone_set('Asia/Jakarta');

$host = 'localhost';
$db = 'peduliyuk_api';
$user = 'root';
$pass = '';
$conn = new mysqli($host, $user, $pass, $db,'3309');
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
?>