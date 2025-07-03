<?php
include 'db.php';

header('Content-Type: application/json');

$response = array();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);

    $admin_id = $data['admin_id'] ?? null;

    if (empty($admin_id)) {
        $response['status'] = 'error';
        $response['message'] = 'ID Admin tidak disediakan.';
        echo json_encode($response);
        exit();
    }

    try {
        $query = "SELECT id, username, email, photo, no_telp FROM users WHERE id = ? AND role = 'admin'";
        $stmt = $conn->prepare($query);

        if (!$stmt) {
            $response['status'] = 'error';
            $response['message'] = 'Failed to prepare statement: ' . $conn->error;
            echo json_encode($response);
            $conn->close();
            exit();
        }

        $stmt->bind_param("i", $admin_id);

        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows > 0) {
            $adminData = $result->fetch_assoc();
            $response['status'] = 'success';
            $response['message'] = 'Profil admin berhasil diambil.';
            $response['admin'] = $adminData;
        } else {
            $response['status'] = 'error';
            $response['message'] = 'Admin tidak ditemukan atau ID tidak valid.';
        }

        $stmt->close();

    } catch (Exception $e) {
        $response['status'] = 'error';
        $response['message'] = 'Database error: ' . $e->getMessage();
    }
} else {
    $response['status'] = 'error';
    $response['message'] = 'Metode request tidak diizinkan. Metode yang diterima: POST';
}

echo json_encode($response);
$conn->close();
?>