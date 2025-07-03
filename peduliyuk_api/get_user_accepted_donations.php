<?php
include 'db.php';

header('Content-Type: application/json');

if (!isset($_GET['receiver_id'])) {
    echo json_encode(['status' => 'error', 'message' => 'Receiver ID is required.']);
    exit;
}

$receiver_id = $conn->real_escape_string($_GET['receiver_id']);

$sql = "
    SELECT
        da.id,
        da.id_donation,
        da.id_receiver,
        da.tanggal_pengambilan,
        da.delivery_method,
        da.scheduled_delivery_date,
        d.type AS donation_type,
        d.status,
        d.accept_to,
        -- Tambahkan CASE statement untuk total_quantity di sini
        CASE
            WHEN d.type = 'barang' THEN (SELECT COUNT(id) FROM barang WHERE donation_id = d.id)
            WHEN d.type = 'pakaian' THEN (SELECT COUNT(id) FROM pakaian WHERE donation_id = d.id)
            ELSE 0
        END AS total_quantity,
        u.username AS donor_username,
        u.photo AS donor_photo,
        u.no_telp AS donor_no_telp
    FROM
        donation_acceptance da
    JOIN
        donations d ON da.id_donation = d.id
    JOIN
        users u ON d.id_user = u.id
    WHERE
        da.id_receiver = '$receiver_id' AND d.status IN ('Found Receiver', 'On Delivery', 'Received')
    ORDER BY
        da.tanggal_pengambilan DESC;
";

$result = $conn->query($sql);

$donations = [];
if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $donations[] = $row;
    }
    echo json_encode(['status' => 'success', 'donations' => $donations]);
} else {
    echo json_encode(['status' => 'success', 'donations' => [], 'message' => 'No ongoing donations found for this receiver.']);
}

$conn->close();
?>