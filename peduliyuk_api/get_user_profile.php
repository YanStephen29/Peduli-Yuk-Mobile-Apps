<?php
include 'db.php';
header('Content-Type: application/json; charset=UTF-8');

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $userId = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;
    if ($userId <= 0) {
        echo json_encode(['status' => 'error', 'message' => 'ID Pengguna tidak valid.']);
        exit();
    }
    $stmt = $conn->prepare("
        SELECT
    u.id,
    u.username,
    u.email,
    u.role,
    u.photo,
    u.no_telp,
    m.age,
    m.address,
    (SELECT AVG(da.rating) 
     FROM donation_acceptance da 
     JOIN donations d ON da.id_donation = d.id 
     WHERE d.id_user = u.id) AS average_rating
FROM 
    users u
LEFT JOIN 
    masyarakat m ON u.id = m.user_id
WHERE 
    u.id = ?
    ");
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $userData = $result->fetch_assoc();
        if ($userData['average_rating'] === null) {
            $userData['average_rating'] = 0;
        }
        echo json_encode(['status' => 'success', 'user_data' => $userData]);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Pengguna tidak ditemukan.']);
    }
    $stmt->close();
    $conn->close();
} else {
    echo json_encode(['status' => 'error', 'message' => 'Metode permintaan tidak valid.']);
}
?>