package com.fintrack.report;

import java.io.IOException;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.nio.charset.StandardCharsets;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.StreamingResponseBody;

@Service
public class CsvExportService {

  private static final byte[] UTF8_BOM = {(byte) 0xEF, (byte) 0xBB, (byte) 0xBF};
  private static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.ISO_LOCAL_DATE;

  private static final String EXPORT_QUERY =
      """
        SELECT t.date,
               t.type,
               c.name AS category_name,
               a.name AS account_name,
               ta.name AS transfer_account_name,
               t.amount,
               t.note
        FROM transactions t
        JOIN accounts a ON a.id = t.account_id AND a.user_id = t.user_id
        LEFT JOIN categories c ON c.id = t.category_id AND c.user_id = t.user_id
        LEFT JOIN accounts ta ON ta.id = t.transfer_account_id AND ta.user_id = t.user_id
        WHERE t.user_id = ?
          AND t.date >= ?
          AND t.date <= ?
        ORDER BY t.date ASC, t.created_at ASC
        """;

  private final JdbcTemplate jdbcTemplate;

  public CsvExportService(JdbcTemplate jdbcTemplate) {
    this.jdbcTemplate = jdbcTemplate;
  }

  public CsvExportResult export(UUID userId, LocalDate from, LocalDate to) {
    String filename = "fintrack_" + from + "_" + to + ".csv";
    StreamingResponseBody body = outputStream -> writeCsv(userId, from, to, outputStream);
    return new CsvExportResult(filename, body);
  }

  private void writeCsv(UUID userId, LocalDate from, LocalDate to, OutputStream outputStream)
      throws IOException {
    outputStream.write(UTF8_BOM);

    try (Writer writer = new OutputStreamWriter(outputStream, StandardCharsets.UTF_8)) {
      writer.write("fecha,tipo,categoria,cuenta,cuenta_destino,monto,nota\n");

      jdbcTemplate.query(
          EXPORT_QUERY,
          rs -> {
            try {
              writer.write(formatRow(rs));
            } catch (IOException ex) {
              throw new CsvWriteException(ex);
            }
          },
          userId,
          from,
          to);

      writer.flush();
    } catch (CsvWriteException ex) {
      throw ex.ioException();
    }
  }

  private String formatRow(ResultSet rs) throws SQLException {
    return String.join(
            ",",
            escapeCsv(rs.getDate("date").toLocalDate().format(DATE_FORMAT)),
            escapeCsv(rs.getString("type")),
            escapeCsv(rs.getString("category_name")),
            escapeCsv(rs.getString("account_name")),
            escapeCsv(rs.getString("transfer_account_name")),
            escapeCsv(rs.getBigDecimal("amount").setScale(2).toPlainString()),
            escapeCsv(rs.getString("note")))
        + "\n";
  }

  static String escapeCsv(String value) {
    if (value == null) {
      return "";
    }
    if (value.contains(",")
        || value.contains("\"")
        || value.contains("\n")
        || value.contains("\r")) {
      return "\"" + value.replace("\"", "\"\"") + "\"";
    }
    return value;
  }

  public record CsvExportResult(String filename, StreamingResponseBody body) {}

  private static final class CsvWriteException extends RuntimeException {

    private CsvWriteException(IOException cause) {
      super(cause);
    }

    private IOException ioException() {
      return (IOException) getCause();
    }
  }
}
