<?php
require_once 'db.php';

header('Content-Type: application/json');

$response = array();

try {
    $user_id = $_GET['user_id'] ?? null;

    $sql = "SELECT 
                sk.id, sk.user_id, sk.title, sk.description, sk.image_url, sk.created_at, sk.deadline, 
                u.username,
                u.role,
                COALESCE(umkm.organization_name, ls.organization_name) AS organization_name,
                COALESCE(umkm.address, ls.address) AS address
            FROM 
                suara_kebutuhan sk
            JOIN 
                users u ON sk.user_id = u.id
            LEFT JOIN 
                umkm ON u.id = umkm.user_id
            LEFT JOIN 
                lembaga_sosial ls ON u.id = ls.user_id";
    
    if ($user_id !== null && is_numeric($user_id)) {
        $sql .= " WHERE sk.user_id = ?";
    }

    $sql .= " ORDER BY sk.created_at DESC";

    $stmt = $conn->prepare($sql);

    if ($stmt) {
        if ($user_id !== null && is_numeric($user_id)) {
            $stmt->bind_param("i", $user_id);
        }
        
        $stmt->execute();
        $result = $stmt->get_result();

        $suaraKebutuhanList = array();
        while ($row = $result->fetch_assoc()) {
            $row['created_at'] = date('Y-m-d H:i:s', strtotime($row['created_at']));
            if ($row['deadline']) {
                $row['deadline'] = date('Y-m-d H:i:s', strtotime($row['deadline']));
            }

            if ($row['organization_name'] === null) {
                $row['organization_name'] = 'Masyarakat Umum';
            }
            if ($row['address'] === null) {
                $row['address'] = 'Tidak ada alamat';
            }
            
            switch ($row['role']) {
                case 'lembaga_sosial':
                    $row['role'] = 'Lembaga Sosial';
                    break;

                case 'umkm':
                    $row['role'] = 'UMKM';
                    break;
            }

            $suaraKebutuhanList[] = $row;
        }
        $response['status'] = 'success';
        $response['message'] = 'Suara kebutuhan fetched successfully.';
        $response['suara_kebutuhan'] = $suaraKebutuhanList;
        $stmt->close();
    } else {
        $response['status'] = 'error';
        $response['message'] = 'Failed to prepare statement: ' . $conn->error;
    }
} catch (Exception $e) {
    $response['status'] = 'error';
    $response['message'] = 'Server error: ' . $e->getMessage();
}

echo json_encode($response);

$conn->close();
?>