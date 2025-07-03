<?php
header('Content-Type: application/json');
include 'db.php';

$response = array();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);
    $user_id = $data['user_id'] ?? null;

    if (empty($user_id)) {
        $response['status'] = 'error';
        $response['message'] = 'ID Pengguna tidak disediakan.';
        echo json_encode($response);
        exit();
    }

    try {   
        $stmt = $conn->prepare("
            SELECT
                u.id,
                u.username,
                u.email,
                u.no_telp,
                u.photo,
                u.role,
                (SELECT AVG(da.rating) 
                 FROM donation_acceptance da 
                 JOIN donations d ON da.id_donation = d.id 
                 WHERE d.id_user = u.id) AS rating
            FROM
                users u
            WHERE
                u.id = ?
        ");

        $stmt->bind_param("i", $user_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $user = $result->fetch_assoc();
        $stmt->close();

        if ($user) {
            if ($user['rating'] === null) {
                $user['rating'] = 0.0;
            }

            $response['status'] = 'success';
            $response['message'] = 'Detail pengguna berhasil diambil.';
            $response['user'] = $user;
        } else {
            $response['status'] = 'error';
            $response['message'] = 'Pengguna tidak ditemukan.';
        }
    } catch (Exception $e) {
        $response['status'] = 'error';
        $response['message'] = $e->getMessage();
    }
} else {
    $response['status'] = 'error';
    $response['message'] = 'Metode request tidak diizinkan.';
}

echo json_encode($response);
$conn->close();
?>