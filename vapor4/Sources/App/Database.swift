import MySQLKit
import SQLKit
import Foundation

struct Database {
    
    // CREATE TABLE IF NOT EXISTS events (
    //     id          INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    //     title       VARCHAR(128)     NOT NULL,
    //     public_fg   TINYINT(1)       NOT NULL,
    //     closed_fg   TINYINT(1)       NOT NULL,
    //     price       INTEGER UNSIGNED NOT NULL
    // ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    struct Event: Codable {
        let id: UInt32
        var title: String
        var public_fg: Bool
        var close_fg: Bool
        var price: UInt32
    }

    // CREATE TABLE IF NOT EXISTS sheets (
    //     id          INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    //     `rank`      VARCHAR(128)     NOT NULL,
    //     num         INTEGER UNSIGNED NOT NULL,
    //     price       INTEGER UNSIGNED NOT NULL,
    //     UNIQUE KEY rank_num_uniq (`rank`, num)
    // ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    struct Sheet: Codable {
        let id: UInt32
        var rank: String
        var num: UInt32
        var price: UInt32
        var mine: Bool = false
        var reserved: Bool = false
    }
    
    struct Sheets {
        var details: [Sheet] = []
        var total: Int
        var remains: Int
        var price: Int
    }
    
    // CREATE TABLE IF NOT EXISTS reservations (
    //     id          INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    //     event_id    INTEGER UNSIGNED NOT NULL,
    //     sheet_id    INTEGER UNSIGNED NOT NULL,
    //     user_id     INTEGER UNSIGNED NOT NULL,
    //     reserved_at DATETIME(6)      NOT NULL,
    //     canceled_at DATETIME(6)      DEFAULT NULL,
    //     KEY event_id_and_sheet_id_idx (event_id, sheet_id)
    // ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    struct Reservation: Codable {
        let id: UInt32
        var event_id: UInt32
        var sheet_id: UInt32
        var user_id: UInt32
        var reserved_at: Date
        var canceled_at: Date
    }
    
    struct Error: Swift.Error, CustomStringConvertible {
        let description: String
    }

    let connection: MySQLConnection

    func getEvents(all: Bool) async throws -> [Event] {
        let rows = try await connection.sql().select()
            .column("*")
            .from("events")
            .orderBy("id", .ascending)
            .all(decoding: Event.self)
            .get()
        return rows.compactMap { event in
            if !all && !event.public_fg {
                return nil
            }
            return event
        }
    }

    func getEvent(eventID: UInt32, loginUserID: UInt32?) async throws -> (
        event: Event,
        total: Int,
        sheets: [String: Sheets]
    ) {
        var total: Int = 0
        var remains: Int = 0
        var sheetsByRank: [String: Sheets] = [:]

        let maybeEvent = try await connection.sql().select()
            .column("*")
            .from("events")
            .where("id", .equal, eventID)
            .first(decoding: Event.self).get()
        guard let event = maybeEvent else {
            throw Error(description: "no event found for id \(eventID)")
        }

        for rank in ["S", "A", "B", "C"] {
            sheetsByRank[rank] = Sheets(total: 0, remains: 0, price: 0)
        }

        let sheets = try await connection
            .sql().raw("SELECT * FROM sheets ORDER BY `rank`, num")
            .all(decoding: Sheet.self).get()

        for sheet in sheets {
            if sheetsByRank[sheet.rank]!.price == 0 {
                sheetsByRank[sheet.rank]?.price = Int(event.price + sheet.price)
            }
            
            total += 1
            sheetsByRank[sheet.rank]?.total += 1

            let reservation = try await connection.sql()
                .select().column("*").from("reservations")
                .where("event_id", .equal, eventID)
                .first(decoding: Reservation.self)
                .get()

            var sheet = sheet
            if let reservation = reservation {
                if let loginUserID = loginUserID, reservation.user_id == loginUserID {
                    sheet.mine = true
                }
                sheet.reserved = true
            } else {
                remains += 1
                sheetsByRank[sheet.rank]?.remains += 1
            }
            sheetsByRank[sheet.rank]?.details.append(sheet)
        }
        return (event, total, sheetsByRank)
    }
}
