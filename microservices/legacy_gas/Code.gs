var BACKEND_URL = PropertiesService.getScriptProperties().getProperty("BACKEND_URL") || "https://your-2r-backend.example.com";
var API_TOKEN   = PropertiesService.getScriptProperties().getProperty("API_TOKEN")   || "";

function getAuthHeaders() {
  return {
    "Content-Type":  "application/json",
    "Authorization": "Bearer " + API_TOKEN,
  };
}

function fetchReservations() {
  var response = UrlFetchApp.fetch(BACKEND_URL + "/api/reservations", {
    method:  "GET",
    headers: getAuthHeaders(),
    muteHttpExceptions: true,
  });

  if (response.getResponseCode() !== 200) {
    Logger.log("fetchReservations failed: " + response.getContentText());
    return [];
  }

  var data = JSON.parse(response.getContentText());
  return data.data || data;
}

function pushReservationToCalendar(reservation) {
  var calendar = CalendarApp.getDefaultCalendar();
  var title     = reservation.title    || reservation.room_id;
  var startTime = new Date(reservation.start_time);
  var endTime   = new Date(reservation.end_time);

  var event = calendar.createEvent(title, startTime, endTime, {
    description: "2R Reservation — Room: " + reservation.room_id +
                 "\nID: " + (reservation.id || reservation.client_id),
  });

  Logger.log("Calendar event created: " + event.getId());
  return event.getId();
}

function syncReservationsToCalendar() {
  var reservations = fetchReservations();
  var synced = 0;

  for (var i = 0; i < reservations.length; i++) {
    var r = reservations[i];
    if (r.status === "confirmed") {
      try {
        pushReservationToCalendar(r);
        synced++;
      } catch (e) {
        Logger.log("Error syncing reservation " + r.id + ": " + e.message);
      }
    }
  }

  Logger.log("Synced " + synced + " reservations to Google Calendar");
  return synced;
}

function createReservationFromSheet() {
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
  var data  = sheet.getDataRange().getValues();

  for (var i = 1; i < data.length; i++) {
    var row = data[i];
    if (!row[0]) continue;

    var payload = {
      room_id:    String(row[0]),
      title:      String(row[1]),
      start_time: new Date(row[2]).toISOString(),
      end_time:   new Date(row[3]).toISOString(),
    };

    var response = UrlFetchApp.fetch(BACKEND_URL + "/api/reservations", {
      method:             "POST",
      headers:            getAuthHeaders(),
      payload:            JSON.stringify(payload),
      muteHttpExceptions: true,
    });

    var code = response.getResponseCode();
    if (code === 201) {
      sheet.getRange(i + 1, 5).setValue("SYNCED");
    } else {
      sheet.getRange(i + 1, 5).setValue("ERROR: " + code);
    }
  }
}

function doGet(e) {
  var action = e.parameter.action || "list";

  if (action === "list") {
    var reservations = fetchReservations();
    return ContentService
      .createTextOutput(JSON.stringify(reservations))
      .setMimeType(ContentService.MimeType.JSON);
  }

  return ContentService
    .createTextOutput(JSON.stringify({ error: "unknown action" }))
    .setMimeType(ContentService.MimeType.JSON);
}
