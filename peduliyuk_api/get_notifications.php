<?php
include 'db.php';

$query = "SELECT * FROM notifications ORDER BY created_at DESC";
$result = mysqli_query($conn, $query);
$notifications = [];

while ($row = mysqli_fetch_assoc($result)) {
    $notifications[] = $row;
}

echo json_encode(['status' => 'success', 'notifications' => $notifications]);
mysqli_close($conn);
?>
