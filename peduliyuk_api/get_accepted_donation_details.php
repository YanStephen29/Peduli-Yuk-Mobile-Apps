<?php
include 'db.php'; 

header('Content-Type: application/json');

if (!isset($_GET['donation_acceptance_id'])) {
    echo json_encode(['status' => 'error', 'message' => 'Donation Acceptance ID is required.']);
    exit;
}

$donation_acceptance_id = $conn->real_escape_string($_GET['donation_acceptance_id']);

$sql_main = "
    SELECT
        da.id AS donation_acceptance_id,
        da.id_donation,
        da.id_receiver,
        da.tanggal_pengambilan,
        da.delivery_method,
        da.scheduled_delivery_date,
        -- Kolom baru dari donation_acceptance
        da.received_at,
        da.received_photo_url,
        da.rating,
        da.feedback_comment,

        d.id AS donation_id,
        d.type AS donation_type,
        -- d.description AS donation_description, -- KOLOM INI TIDAK ADA DI TABLE donations, DIHAPUS
        d.status AS donation_status, -- Status donasi utama masih di tabel donations
        d.created_at AS donation_created_at,
        d.accept_to,
        d.id_user AS donor_user_id,
        u.username AS donor_username,
        u.email AS donor_email,
        u.photo AS donor_photo,
        u.no_telp AS donor_no_telp,
        CASE
            WHEN u.role = 'masyarakat' THEN (SELECT address FROM masyarakat WHERE user_id = u.id)
            WHEN u.role = 'UMKM' THEN (SELECT address FROM umkm WHERE user_id = u.id)
            WHEN u.role = 'lembaga_sosial' THEN (SELECT address FROM lembaga_sosial WHERE user_id = u.id)
            ELSE NULL
        END AS donor_address,
        CASE
            WHEN d.type = 'barang' THEN (SELECT COUNT(id) FROM barang WHERE donation_id = d.id)
            WHEN d.type = 'pakaian' THEN (SELECT COUNT(id) FROM pakaian WHERE donation_id = d.id)
            ELSE 0
        END AS total_quantity
    FROM
        donation_acceptance da
    JOIN
        donations d ON da.id_donation = d.id
    JOIN
        users u ON d.id_user = u.id
    WHERE
        da.id = '$donation_acceptance_id'
    LIMIT 1;
";

$result_main = $conn->query($sql_main);

if (!$result_main) {
    echo json_encode(['status' => 'error', 'message' => 'Database query failed for main data: ' . $conn->error]);
    exit;
}

if ($result_main->num_rows > 0) {
    $main_data = $result_main->fetch_assoc();
    $donation_id = $main_data['donation_id'];
    $donation_type = $main_data['donation_type'];
    $items = [];

    if ($donation_type == 'barang') {
        $sql_items = "SELECT id, item_name, size, defects, front_photo_url, back_photo_url FROM barang WHERE donation_id = '$donation_id'";
        $result_items = $conn->query($sql_items);
        if (!$result_items) {
            error_log("Error fetching barang details: " . $conn->error);
        } else if ($result_items->num_rows > 0) {
            while ($row_item = $result_items->fetch_assoc()) {
                $items[] = $row_item;
            }
        }
    } elseif ($donation_type == 'pakaian') {
        $sql_items = "SELECT id, clothing_type AS item_type, size, defects, front_photo_url, back_photo_url FROM pakaian WHERE donation_id = '$donation_id'";
        $result_items = $conn->query($sql_items);
         if (!$result_items) {
            error_log("Error fetching pakaian details: " . $conn->error);
        } else if ($result_items->num_rows > 0) {
            while ($row_item = $result_items->fetch_assoc()) {
                $items[] = $row_item;
            }
        }
    }

    $main_data['items'] = $items;
    echo json_encode(['status' => 'success', 'donation_details' => $main_data]);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Donation details not found.']);
}

$conn->close();
?>