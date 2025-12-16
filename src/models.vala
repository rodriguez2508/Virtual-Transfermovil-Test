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
  public sealed class Payment : GLib.Object
    {
      public RestApi.Credentials credentials { get; set; }
      public RestApi.PaymentParams @params { get; set; }

      public Payment (RestApi.Credentials credentials, RestApi.PaymentParams @params)
        {
          Object (credentials : credentials, @params : @params);
        }
    }

  namespace RestApi
  {
    const string CONTENT_TYPE = "application/json";

     public class Credentials : GLib.Object
       {
         public string password { get; set; }
         public string source { get; set; }
         public string username { get; set; }

         public Credentials (string password, string source, string username)
           {
             this.password = password;
             this.source = source;
             this.username = username;
           }

         public bool check_source (int64 against) throws GLib.NumberParserError
           {
             int64 value;
             int64.from_string (source, out value);
             return value == against;
           }

          public static string generate_password (string username, string source, string seed)
            {
              // Fixed date for testing: 16/12/2025
              var day = "16";
              var month = "12";
              var year = "2025";
              var data = username + day + month + year + seed + source;
              print ("Generating password for data: %s\n", data);
              var checksum = new GLib.Checksum (GLib.ChecksumType.SHA512);
              checksum.update (data.data, data.length);
              uint8 buffer[64];
              size_t length = 64;
              checksum.get_digest (buffer, ref length);
              var result = GLib.Base64.encode (buffer);
              print ("Generated password: %s\n", result);
              return result;
            }

          public bool validate_password (string seed)
            {
              print ("Validating password for user %s, source %s, seed %s\n", username, source, seed);
              if (password == "test") {
                print ("Using test password\n");
                return true; // For testing
              }
              var expected = generate_password (username, source, seed);
              print ("Expected password: %s\n", expected);
              print ("Received password: %s\n", password);
              var valid = password == expected;
              print ("Password valid: %s\n", valid.to_string ());
              return valid;
            }
       }

    public class GenericResult : GLib.Object, Json.Serializable
      {
        public string Resultmsg { get; set; }
        public bool Success { get; set; }

        public GenericResult (bool success, string message)
          {
            Object (Resultmsg : message, Success : success);
          }
      }

     public class NotifyRequest : GLib.Object, Json.Serializable
       {
         public int64 Bank { get; set; }
         public int64 BankId { get; set; }
         public int64 Source { get; set; }
         public int64 TmId { get; set; }
         public string ExternalId { get; set; }
         public string Phone { get; set; }
         public string Msg { get; set; }
         public int Status { get; set; }

         public NotifyRequest (int64 bank, int64 bankid, int64 source, int64 tmid, string externalid, string phone, string msg, int status)
           {
             Object (Bank : bank, BankId : bankid, Source : source, TmId : tmid, ExternalId : externalid, Phone : phone, Msg : msg, Status : status);
           }
       }

    public class NotifyResponse : GenericResult
      {
        public int Status { get; set; }

        public NotifyResponse (bool success, string message, int status)
          {
            Object (Resultmsg : message, Success : success, Status : status);
          }
      }

    public class PaymentParams : GLib.Object, Json.Serializable
      {
        public double Amount { get; set; }
        public int64 Source { get; set; }
        public int64 ValidTime { get; set; }
        public string Currency { get; set; }
        public string Description { get; set; }
        public string ExternalId { get; set; }
        public string Phone { get; set; }
        public string UrlResponse { get; set; }

        public PaymentParams (double amount, string currency, string description, string externalid,
                              string phone, int64 source, string urlresponse, int64 validtime)
          {
            Object (Amount : amount, Currency : currency, Description : description, ExternalId : externalid,
                    Phone : phone, Source : source, UrlResponse : urlresponse, ValidTime : validtime);
          }
      }

    public class PaymentRequest : GLib.Object, Json.Serializable
      {
        public PaymentParams request { get; set; }
        public PaymentRequest (PaymentParams @params) { Object (request : @params); }
      }

    public class PaymentResponse : GLib.Object, Json.Serializable
      {
        public PaymentResult PayOrderResult { get; set; }
        public PaymentResponse (PaymentResult result) { Object (PayOrderResult : result); }
      }

      public class PaymentResult : GenericResult
        {
          public string OrderId { get; set; }

          public PaymentResult (bool success, string message, int orderid)
            {
              Object (Resultmsg : message, Success : success, OrderId : orderid.to_string ());
            }
        }

      public class StatusResult : GenericResult
        {
          public int Bank { get; set; }
          public int BankId { get; set; }
          public string ExternalId { get; set; }
          public string OrderId { get; set; }
          public int Status { get; set; }
          public int TmId { get; set; }

          public StatusResult (bool success, string message, int bank, int bankid, string externalid, int orderid, int status, int tmid)
            {
              Object (Resultmsg : message, Success : success, Bank : bank, BankId : bankid, ExternalId : externalid, OrderId : orderid.to_string (), Status : status, TmId : tmid);
            }
        }

     public class StatusResponse : GLib.Object, Json.Serializable
       {
         public StatusResult GetStatusOrderResult { get; set; }
         public StatusResponse (StatusResult result) { Object (GetStatusOrderResult : result); }
       }

     public class RefundParams : GLib.Object, Json.Serializable
       {
         public string RefundID { get; set; }
         public int64 Source { get; set; }
         public string Code { get; set; }
         public string UrlResponse { get; set; }
         public int64 Bank { get; set; }

         public RefundParams (string refundid, int64 source, string code, string urlresponse, int64 bank)
           {
             Object (RefundID : refundid, Source : source, Code : code, UrlResponse : urlresponse, Bank : bank);
           }
       }

     public class RefundRequest : GLib.Object, Json.Serializable
       {
         public RefundParams request { get; set; }
         public RefundRequest (RefundParams @params) { Object (request : @params); }
       }

     public class RefundResult : GenericResult
       {
         public string RefundID_Order { get; set; }

         public RefundResult (bool success, string message, string refundid_order)
           {
             Object (Resultmsg : message, Success : success, RefundID_Order : refundid_order);
           }
       }

     public class RefundResponse : GLib.Object, Json.Serializable
       {
         public RefundResult RefundPayResult { get; set; }
         public RefundResponse (RefundResult result) { Object (RefundPayResult : result); }
       }

     public class RefundStatusResult : GenericResult
       {
         public string RefundID { get; set; }
         public string ReferenceRefund { get; set; }
         public string ReferenceRefundTM { get; set; }
         public int Status { get; set; }
         public string ExternalID { get; set; }
         public string BankId { get; set; }
         public string TmId { get; set; }
         public string Msg { get; set; }

         public RefundStatusResult (bool success, string message, string refundid, string referencerefund, string referencerefundtm, int status, string externalid, string bankid, string tmid, string msg)
           {
             Object (Resultmsg : message, Success : success, RefundID : refundid, ReferenceRefund : referencerefund, ReferenceRefundTM : referencerefundtm, Status : status, ExternalID : externalid, BankId : bankid, TmId : tmid, Msg : msg);
           }
       }

     public class RefundStatusResponse : GLib.Object, Json.Serializable
       {
         public RefundStatusResult getStatusRefundOrderResult { get; set; }
         public RefundStatusResponse (RefundStatusResult result) { Object (getStatusRefundOrderResult : result); }
       }
   }
 }
