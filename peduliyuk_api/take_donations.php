<?php
require 'db.php';

$response = [];
$data = json_decode(file_get_contents("php://input"));

if (isset($data->donation_id) && isset($data->receiver_id)) {
    $donation_id = intval($data->donation_id);
    $receiver_id = intval($data->receiver_id);

    $conn->begin_transaction();

    try {
        $stmt1 = $conn->prepare("UPDATE donations SET status = 'Found Receiver' WHERE id = ? AND status = 'Waiting For Receiver'");
        $stmt1->bind_param("i", $donation_id);
        $stmt1->execute();
        
        if ($stmt1->affected_rows === 0) {
            throw new Exception("Donasi mungkin sudah diambil atau tidak tersedia.");
        }
        
        $stmt2 = $conn->prepare("INSERT INTO donation_acceptance (id_donation, id_receiver) VALUES (?, ?)");
        $stmt2->bind_param("ii", $donation_id, $receiver_id);
        $stmt2->execute();
        
        $conn->commit();
        $response = ['status' => 'success', 'message' => 'Donasi berhasil diambil.'];

    } catch (Exception $e) {
        $conn->rollback();
        $response = ['status' => 'error', 'message' => $e->getMessage()];
        http_response_code(500);
    }

} else {
    $response = ['status' => 'error', 'message' => 'Parameter tidak lengkap.'];
    http_response_code(400);
}

echo json_encode($response);
$conn->close();
?>