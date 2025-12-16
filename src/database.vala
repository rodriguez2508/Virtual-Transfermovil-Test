/* Copyright 2023-2025 MarcosHCK
 * This file is part of virtualtm.
 *
 * virtualtm is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * virtualtm is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with virtualtm. If not, see <http://www.gnu.org/licenses/>.
 */

namespace VirtualTM
{
  public errordomain DatabaseError
    {
      FAILED,
      INSERT,
      SELECT,
      OPEN;

      public extern static GLib.Quark quark ();
    }

  public sealed class Database : GLib.Object, GLib.Initable
    {
      /* properties */
      public string filename { get; construct; }

       /* database and statements */
       private Sqlite.Database sqlite;
       private Sqlite.Statement insert_stmt;
       private Sqlite.Statement select_payment_stmt;
       private Sqlite.Statement select_pending_stmt;
       private Sqlite.Statement update_pending_stmt;
       private Sqlite.Statement insert_refund_stmt;
       private Sqlite.Statement select_refund_status_stmt;
       private Sqlite.Statement select_payment_status_stmt;

      /* constants */

      /* columns from data */
      private const string column_amount = "Amount";
      private const string column_currency = "Currency";
      private const string column_description = "Description";
      private const string column_externalid = "ExternalId";
      private const string column_phone = "Phone";
      private const string column_source = "Source";
      private const string column_urlresponse = "UrlResponse";
      private const string column_validtime = "ValidTime";

      /* columns from headers */
      private const string column_password = "Password";
      private const string column_username = "Username";

       /* columns added by logic */
       private const string column_id = "Id";
       private const string column_pending = "Pending";
       private const string column_status = "Status";

       /* refund columns */
       private const string refund_column_id = "Id";
       private const string refund_column_refundid = "RefundID";
       private const string refund_column_source = "Source";
       private const string refund_column_code = "Code";
       private const string refund_column_urlresponse = "UrlResponse";
       private const string refund_column_bank = "Bank";
       private const string refund_column_status = "Status";
       private const string refund_column_referencerefund = "ReferenceRefund";
       private const string refund_column_referencerefundtm = "ReferenceRefundTM";
       private const string refund_column_externalid = "ExternalID";
       private const string refund_column_bankid = "BankId";
       private const string refund_column_tmid = "TmId";
       private const string refund_column_msg = "Msg";

       /* database */
       private const string table_name = "Payment";
       private const string refund_table_name = "Refund";

      /* queries template */
       private const string insert_sql
           = "INSERT INTO " + table_name + " ("
           + column_amount + ", " + column_currency + ", " + column_description + ", "
           + column_externalid + ", " + column_phone + ", " + column_source + ", "
           + column_urlresponse + ", " + column_validtime + ", " + column_password + ", "
           + column_username + ", " + column_status + ") "
           + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);";
       private const string select_payment_sql
           = "SELECT "
           + column_amount + ", " + column_currency + ", " + column_description + ", "
           + column_externalid + "," + column_phone + ", " + column_source + ", "
           + column_urlresponse + ", " + column_validtime + ", " + column_password + ", "
           + column_username + ", " + column_status + " "
           + "FROM " + table_name + " "
           + "WHERE " + column_externalid + " = ?;";
      private const string select_pending_sql
          = "SELECT "
            + column_externalid + " "
          + "FROM " + table_name + " "
          + "WHERE " + column_pending + " = 1;";
       private const string update_pending_sql
           = "UPDATE " + table_name + " "
           + "SET " + column_pending + " = ? "
           + "WHERE " + column_externalid + " = ?;";
       private const string insert_refund_sql
           = "INSERT INTO " + refund_table_name + " ("
           + refund_column_refundid + ", " + refund_column_source + ", " + refund_column_code + ", "
           + refund_column_urlresponse + ", " + refund_column_bank + ") "
           + "VALUES (?, ?, ?, ?, ?);";
       private const string select_refund_status_sql
           = "SELECT "
           + refund_column_refundid + ", " + refund_column_referencerefund + ", " + refund_column_referencerefundtm + ", "
           + refund_column_status + ", " + refund_column_externalid + ", " + refund_column_bankid + ", "
           + refund_column_tmid + ", " + refund_column_msg + " "
           + "FROM " + refund_table_name + " "
           + "WHERE " + refund_column_refundid + " = ? AND " + refund_column_source + " = ?;";
       private const string select_payment_status_sql
           = "SELECT "
           + column_externalid + ", " + column_id + ", " + column_status + " "
           + "FROM " + table_name + " "
           + "WHERE " + column_externalid + " = ? AND " + column_source + " = ?;";

      /* api */

      /*
       * Little complain first. SQLite statements uses 1-indexing for parameters, but
       * uses instead 0-indexing for column retrieval, FOR GOD'S SAKE.
       */

      public Database (string filename, GLib.Cancellable? cancellable = null) throws GLib.Error
        {
          Object (filename : filename);
          this.init (cancellable);
        }

      public bool init (GLib.Cancellable? cancellable = null) throws GLib.Error
        {
          if (unlikely (Sqlite.Database.open_v2 (filename, out sqlite, Sqlite.OPEN_READWRITE) != Sqlite.OK))
            throw new DatabaseError.OPEN (sqlite.errmsg ());
          if (unlikely (sqlite.prepare_v2 (insert_sql, -1, out insert_stmt) != Sqlite.OK))
            throw new DatabaseError.OPEN (sqlite.errmsg ());
          if (unlikely (sqlite.prepare_v2 (select_payment_sql, -1, out select_payment_stmt) != Sqlite.OK))
            throw new DatabaseError.OPEN (sqlite.errmsg ());
          if (unlikely (sqlite.prepare_v2 (select_pending_sql, -1, out select_pending_stmt) != Sqlite.OK))
            throw new DatabaseError.OPEN (sqlite.errmsg ());
           if (unlikely (sqlite.prepare_v2 (update_pending_sql, -1, out update_pending_stmt) != Sqlite.OK))
             throw new DatabaseError.OPEN (sqlite.errmsg ());
           if (unlikely (sqlite.prepare_v2 (insert_refund_sql, -1, out insert_refund_stmt) != Sqlite.OK))
             throw new DatabaseError.OPEN (sqlite.errmsg ());
           if (unlikely (sqlite.prepare_v2 (select_refund_status_sql, -1, out select_refund_status_stmt) != Sqlite.OK))
             throw new DatabaseError.OPEN (sqlite.errmsg ());
           if (unlikely (sqlite.prepare_v2 (select_payment_status_sql, -1, out select_payment_status_stmt) != Sqlite.OK))
             throw new DatabaseError.OPEN (sqlite.errmsg ());
           return true;
        }

      public Payment? get_payment (string externalid) throws GLib.Error
        {
          var errmsg = (string?) null;
          var payment = (Payment?) null;

          select_payment_stmt.bind_text (1, externalid);

          if (unlikely (select_payment_stmt.step () != Sqlite.ROW))
            {
              errmsg = sqlite.errmsg ();
              select_payment_stmt.reset ();
              throw new DatabaseError.SELECT (errmsg);
            }
          else
            {
              payment = new Payment
                (
                  new RestApi.Credentials
                    (
                      select_payment_stmt.column_text (8),
                      select_payment_stmt.column_text (5),
                      select_payment_stmt.column_text (9)
                    ),
                  new RestApi.PaymentParams
                    (
                      select_payment_stmt.column_double (0),
                      select_payment_stmt.column_text (1),
                      select_payment_stmt.column_text (2),
                      select_payment_stmt.column_text (3),
                      select_payment_stmt.column_text (4),
                      select_payment_stmt.column_int64 (5),
                      select_payment_stmt.column_text (6),
                      select_payment_stmt.column_int64 (7)
                    )
                );
 
              if (unlikely (select_payment_stmt.step () != Sqlite.DONE))
                assert_not_reached ();
              else if (unlikely (select_payment_stmt.reset () != Sqlite.OK))
                throw new DatabaseError.SELECT (sqlite.errmsg ());
            }
        return payment;
        }

      public string[] get_pending () throws GLib.Error
        {
          var accum = new GenericArray<string?> ();
          var errmsg = (string?) null;
          var result = Sqlite.OK;

          while (true)
            {
              result = select_pending_stmt.step ();

              if (result == Sqlite.DONE)
                break;
              else if (result == Sqlite.ROW)
                {
                  accum.add (select_pending_stmt.column_text (0));
                }
              else
                {
                  errmsg = sqlite.errmsg ();
                  select_pending_stmt.reset ();
                  throw new DatabaseError.SELECT (errmsg);
                }
            }

          if (unlikely (select_pending_stmt.reset () != Sqlite.OK))
            throw new DatabaseError.SELECT (sqlite.errmsg ());
        return accum.steal ();
        }

       public int register (Payment payment) throws GLib.Error
         {
           print ("Registering payment: ExternalId %s, Amount %f\n", payment.@params.ExternalId, payment.@params.Amount);
           string errmsg;
           insert_stmt.bind_double (1, payment.@params.Amount);
           insert_stmt.bind_text (2, payment.@params.Currency);
           insert_stmt.bind_text (3, payment.@params.Description);
           insert_stmt.bind_text (4, payment.@params.ExternalId);
           insert_stmt.bind_text (5, payment.@params.Phone);
           insert_stmt.bind_int64 (6, payment.@params.Source);
           insert_stmt.bind_text (7, payment.@params.UrlResponse);
           insert_stmt.bind_int64 (8, payment.@params.ValidTime);
            insert_stmt.bind_text (9, payment.credentials.password);
            insert_stmt.bind_text (10, payment.credentials.username);
            insert_stmt.bind_int (11, 2); // Status = en proceso

           if (unlikely (insert_stmt.step () != Sqlite.DONE))
             {
               errmsg = sqlite.errmsg ();
               print ("Insert failed: %s\n", errmsg);
               insert_stmt.reset ();
               throw new DatabaseError.INSERT (errmsg);
             }
           else
             {
               if (unlikely (insert_stmt.reset () != Sqlite.OK))
                 {
                   throw new DatabaseError.INSERT (sqlite.errmsg ());
                 }
             }
         var id = (int) sqlite.last_insert_rowid ();
         print ("Insert successful, id %d\n", id);
         return id;
          }

      public bool update (string externalid, bool pending) throws GLib.Error
        {
          update_pending_stmt.bind_int (1, pending ? 1 : 0);
          update_pending_stmt.bind_text (2, externalid);

          if (unlikely (update_pending_stmt.step () != Sqlite.DONE))
            {
              update_pending_stmt.reset ();
              throw new DatabaseError.INSERT (sqlite.errmsg ());
            }
          else
            {
              if (unlikely (update_pending_stmt.reset () != Sqlite.OK))
                throw new DatabaseError.INSERT (sqlite.errmsg ());
            }
         return true;
         }

        public RestApi.StatusResult? get_payment_status (string externalid, int64 source) throws GLib.Error
          {
            select_payment_status_stmt.bind_text (1, externalid);
            select_payment_status_stmt.bind_int64 (2, source);

            if (unlikely (select_payment_status_stmt.step () != Sqlite.ROW))
              {
                select_payment_status_stmt.reset ();
                return null; // Not found
              }
            else
              {
                var result = new RestApi.StatusResult (true, "Ok", 1, 1234, select_payment_status_stmt.column_text (0), (int) select_payment_status_stmt.column_int64 (1), select_payment_status_stmt.column_int (2), 5678);
                if (unlikely (select_payment_status_stmt.step () != Sqlite.DONE))
                  assert_not_reached ();
                else if (unlikely (select_payment_status_stmt.reset () != Sqlite.OK))
                  throw new DatabaseError.SELECT (sqlite.errmsg ());
                return result;
              }
          }

       public bool register_refund (RestApi.RefundParams @params) throws GLib.Error
         {
           string errmsg;
           insert_refund_stmt.bind_text (1, @params.RefundID);
           insert_refund_stmt.bind_int64 (2, @params.Source);
           insert_refund_stmt.bind_text (3, @params.Code);
           insert_refund_stmt.bind_text (4, @params.UrlResponse);
           insert_refund_stmt.bind_int64 (5, @params.Bank);

           if (unlikely (insert_refund_stmt.step () != Sqlite.DONE))
             {
               errmsg = sqlite.errmsg ();
               insert_refund_stmt.reset ();
               throw new DatabaseError.INSERT (errmsg);
             }
           else
             {
               if (unlikely (insert_refund_stmt.reset () != Sqlite.OK))
                 {
                   throw new DatabaseError.INSERT (sqlite.errmsg ());
                 }
             }
         return true;
         }

       public RestApi.RefundStatusResult? get_refund_status (string refundid, int64 source) throws GLib.Error
         {
           // For testing, return dummy
           return new RestApi.RefundStatusResult (true, "Ok", refundid, "BANK123", "TM456", 3, "123", "BANK789", "TM101", "Test msg");
         }
     }
 }
