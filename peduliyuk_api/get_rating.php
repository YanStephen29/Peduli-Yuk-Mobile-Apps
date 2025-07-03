<?php
include 'db.php';

$query = "SELECT AVG(rating) as avg_rating FROM users";
$result = $conn->query($query);

if ($result && $row = $result->fetch_assoc()) {
    echo json_encode([
        'status' => 'success',
        'rating' => floatval($row['avg_rating'] ?? 0)
    ]);
} else {
    echo json_encode([
        'status' => 'error',
        'message' => 'Gagal mengambil rating'
    ]);
}

mysqli_close($conn);
?>
