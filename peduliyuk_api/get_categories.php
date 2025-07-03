<?php
include 'db.php';

header('Content-Type: application/json');

$query = "SELECT id, name FROM categories";
$result = $conn->query($query);

$categories = [];
if ($result) {
    while ($row = $result->fetch_assoc()) {
        $categories[] = $row;
    }

    echo json_encode([
        'status' => 'success',
        'categories' => $categories
    ]);
} else {
    echo json_encode([
        'status' => 'error',
        'message' => 'Gagal mengambil data kategori'
    ]);
}

$conn->close();
?>