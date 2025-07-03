<?php
include 'db.php';

header('Content-Type: application/json');

$id = $_GET['id'] ?? null;
$data = [];

if ($id) {
    try {
        $query = "
            SELECT c.name 
            FROM article_categories ac
            JOIN categories c ON ac.category_id = c.id
            WHERE ac.article_id = ?
        ";
        $stmt = $conn->prepare($query);

        if (!$stmt) {
            echo json_encode(['status' => 'error', 'message' => 'Failed to prepare statement: ' . $conn->error]);
            $conn->close();
            exit();
        }

        $stmt->bind_param("i", $id);
        $stmt->execute();
        $result = $stmt->get_result();

        while ($row = $result->fetch_assoc()) {
            $data[] = $row['name'];
        }

        $stmt->close();

        echo json_encode(['status' => 'success', 'categories' => $data]);
    } catch (Exception $e) {
        echo json_encode(['status' => 'error', 'message' => 'Database error: ' . $e->getMessage()]);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Missing ID parameter']);
}

$conn->close();
?>