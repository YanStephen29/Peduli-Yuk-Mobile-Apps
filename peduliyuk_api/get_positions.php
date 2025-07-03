<?php
include 'db.php';
header("Content-Type: application/json; charset=UTF-8");

$sql = "SELECT id, name FROM position";
$result = $conn->query($sql);
$positions = [];

if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $row['id'] = (int)$row['id']; 

        $positions[] = $row;
    }
}

echo json_encode(["status" => "success", "positions" => $positions]);
$conn->close();
?>