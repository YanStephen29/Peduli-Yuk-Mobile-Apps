<?php
header('Content-Type: application/json');
require_once 'db.php';

$response = array();

if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['donation_id'])) {
    $donation_id = $_GET['donation_id'];

    if (empty($donation_id)) {
        $response['status'] = 'error';
        $response['message'] = 'ID Donasi tidak disediakan.';
        echo json_encode($response);
        exit();
    }

    try {
        $stmt_donation = $conn->prepare("SELECT id, type, status, created_at, accept_to, id_user FROM donations WHERE id = ?");
        $stmt_donation->bind_param("i", $donation_id);
        $stmt_donation->execute();
        $result_donation = $stmt_donation->get_result();
        $donation_details = $result_donation->fetch_assoc();
        $stmt_donation->close();

        if (!$donation_details) {
            $response['status'] = 'error';
            $response['message'] = 'Donasi tidak ditemukan.';
            echo json_encode($response);
            exit();
        }

        $donation_items = [];
        if ($donation_details['type'] == 'pakaian') {
            $stmt_items = $conn->prepare("SELECT id, donation_id, clothing_type, size, defects, front_photo_url, back_photo_url FROM pakaian WHERE donation_id = ?");
            $stmt_items->bind_param("i", $donation_id);
            $stmt_items->execute();
            $result_items = $stmt_items->get_result();
            while ($row = $result_items->fetch_assoc()) {
                $donation_items[] = $row;
            }
            $stmt_items->close();
        } else if ($donation_details['type'] == 'barang') {
            $stmt_items = $conn->prepare("SELECT id, donation_id, item_name, size, defects, front_photo_url, back_photo_url FROM barang WHERE donation_id = ?");
            $stmt_items->bind_param("i", $donation_id);
            $stmt_items->execute();
            $result_items = $stmt_items->get_result();
            while ($row = $result_items->fetch_assoc()) {
                $donation_items[] = $row;
            }
            $stmt_items->close();
        }

        $response['status'] = 'success';
        $response['message'] = 'Detail donasi berhasil diambil.';
        $response['donation'] = $donation_details;
        $response['items'] = $donation_items;

    } catch (Exception $e) {
        $response['status'] = 'error';
        $response['message'] = $e->getMessage();
    }
} else {
    $response['status'] = 'error';
    $response['message'] = 'Metode request tidak diizinkan atau ID Donasi tidak disediakan.';
}

echo json_encode($response);
$conn->close();
?>