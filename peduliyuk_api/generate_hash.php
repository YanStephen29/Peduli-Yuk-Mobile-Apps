<?php
include 'db.php';
header("Content-Type: application/json; charset=UTF-8");
$password = 'admin123';

$hashedPassword = password_hash($password, PASSWORD_DEFAULT);

echo "Hash Password untuk admin123: <br>" . $hashedPassword;
?>