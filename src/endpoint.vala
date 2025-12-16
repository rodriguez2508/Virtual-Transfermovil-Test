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
using VirtualTM.RestApi;

namespace VirtualTM
{
  public errordomain EndpointError
    {
      FAILED,
      MISSING_FIELD,
      MISSING_HEADER;

      public extern static GLib.Quark quark ();
    }

  public class Endpoint : GLib.Object, GLib.Initable
    {
      private Soup.Server server;

       /* properties */
       public bool local { get; construct; }
       public string endpoint { get; construct; }
       public uint port { get; construct; }
       public string seed { get; construct; }

      /* constants */
      private const string identity = "VirtualTM/" + Config.PACKAGE_VERSION + " ";

       public Endpoint (string endpoint, bool local, uint port, string seed, GLib.Cancellable? cancellable = null) throws GLib.Error
         {
           Object (local : local, endpoint : endpoint, port : port, seed : seed);
           this.init (cancellable);
         }

      public bool init (GLib.Cancellable? cancellable = null) throws GLib.Error
        {
          server = new Soup.Server ("server-header", identity);

          if (local)
            server.listen_local (port, 0);
          else
            server.listen_all (port, 0);

            server.add_handler (endpoint, handle_request);
        return true;
        }

        /*
         * Currently as I'am writing this code Vala has not support for
         * signal accumulators. Ideally `RestAPI::got_request' shold use
         * `g_signal_accumulator_true_handled'-like accumulator so first 
         * handler who returns a valid result sets message response, or
         * fallback to default handler (this one)
         *
         * In this program there will be exactly one handler which will
         * surely handle the request. Even so, the complain is valid.
         *
         * {
         *   // This should be class signal handler
         *   return new RestApi.PaymentResult (false, "Unimplemented", 0);
         * }
         *
         */

       [Signal (no_recurse = true, run = "last")]
       public virtual signal PaymentResult? got_request (RestApi.Credentials credentials, PaymentParams @params);
       [Signal (no_recurse = true, run = "last")]
       public virtual signal RestApi.StatusResult? got_status_request (RestApi.Credentials credentials, string externalid, int64 source);
       [Signal (no_recurse = true, run = "last")]
       public virtual signal RestApi.RefundResult? got_refund_request (RestApi.Credentials credentials, RestApi.RefundParams @params);
       [Signal (no_recurse = true, run = "last")]
       public virtual signal RestApi.RefundStatusResult? got_refund_status_request (RestApi.Credentials credentials, string refundid, int64 source);

      public void shutdown ()
        {
          server.disconnect ();
        }

       private void handle_request (Soup.Server server, Soup.ServerMessage message, string path, GLib.HashTable<string, string>? query)
         {
           unowned var method = message.get_method ();
           unowned var status = Soup.Status.OK;

           if (!path.has_prefix (endpoint))
             {
               status = Soup.Status.NOT_FOUND;
               message.set_status (status, Soup.Status.get_phrase (status));
             }
           else try
             {
               handle_request2 (message, path);
               status = (Soup.Status) message.get_status ();
             }
           catch (GLib.Error e)
             {
               status = Soup.Status.BAD_REQUEST;
               message.set_status (status, Soup.Status.get_phrase (status));
             }
         }

       private void handle_request2 (Soup.ServerMessage message, string path) throws GLib.Error
         {
           unowned var body = message.get_request_body ();
           unowned var headers = message.get_request_headers ();
           unowned var method = message.get_method ();

           /* --- LOGGING START --- */
           print ("\n--- INCOMING REQUEST (PRE-VALIDATION) ---\n");
           print ("Path: %s\n", path);
           print ("Method: %s\n", method);
           print ("Headers:\n");
           headers.foreach((name, value) => {
               print ("  %s: %s\n", name, value);
           });
           print ("Body:\n  %s\n", (string) body.data);
           print ("--- END OF REQUEST ---\n\n");
           /* --- LOGGING END --- */

           var subpath = path.substring (endpoint.length);

           unowned var password = (string?) null;
           unowned var source = (string?) null;
           unowned var username = (string?) null;

           if (unlikely ((password = headers.get_one ("password")) == null))
             throw new EndpointError.MISSING_HEADER ("Missing password header");
           else if (unlikely ((source = headers.get_one ("source")) == null))
             throw new EndpointError.MISSING_HEADER ("Missing source header");
           else if (unlikely ((username = headers.get_one ("username")) == null))
             throw new EndpointError.MISSING_HEADER ("Missing username header");
           else
             {
                var credentials = new RestApi.Credentials (password, source, username);
                print ("Credentials created: user %s, source %s\n", username, source);

               if (subpath == "/payOrder" && method == "POST")
                 {
                    print ("Parsing payment request JSON\n");
                    var payment_object = Json.gobject_from_data (typeof (RestApi.PaymentRequest), (string) body.data, (ssize_t) body.length);
                    if (payment_object == null) {
                      print ("Failed to parse payment request JSON\n");
                      throw new EndpointError.MISSING_FIELD ("Invalid JSON");
                    }
                    var payment = payment_object as RestApi.PaymentRequest;
                    print ("Parsed payment: Amount %f, ExternalId %s, Source %d\n", payment.request.Amount, payment.request.ExternalId, (int) payment.request.Source);
                    credentials.check_source (payment.request.Source);
                    print ("Source check passed\n");
                    var result = got_request (credentials, payment.request);
                    if (result != null)
                      {
                        var json = "{\"PayOrderResult\":{\"Resultmsg\":\"" + result.Resultmsg + "\",\"Success\":" + result.Success.to_string () + ",\"OrderId\":\"" + result.OrderId + "\"}}";
                        print ("Sending payOrder response: %s\n", json);
                        message.set_response ("application/json", Soup.MemoryUse.COPY, json.data);
                      }
                    else
                      message.set_status (Soup.Status.INTERNAL_SERVER_ERROR, Soup.Status.get_phrase (Soup.Status.INTERNAL_SERVER_ERROR));
                 }
               else if (subpath.has_prefix ("/getStatusOrder/") && method == "GET")
                 {
                   var parts = subpath.split ("/");
                   if (parts.length == 4)
                     {
                       var externalid = parts[2];
                       int64 src;
                       if (int64.try_parse (parts[3], out src))
                         {
                           credentials.check_source (src);
                            var result = got_status_request (credentials, externalid, src);
                            if (result != null)
                              {
                                var json = "{\"GetStatusOrderResult\":{\"Resultmsg\":\"" + result.Resultmsg + "\",\"Success\":" + result.Success.to_string () + ",\"Bank\":" + result.Bank.to_string () + ",\"BankId\":" + result.BankId.to_string () + ",\"ExternalId\":\"" + result.ExternalId + "\",\"OrderId\":\"" + result.OrderId + "\",\"Status\":" + result.Status.to_string () + ",\"TmId\":" + result.TmId.to_string () + "}}";
                                print ("Sending getStatusOrder response: %s\n", json);
                                message.set_response ("application/json", Soup.MemoryUse.COPY, json.data);
                              }
                            else
                              message.set_status (Soup.Status.NOT_FOUND, "Payment not found");
                         }
                       else
                         message.set_status (Soup.Status.BAD_REQUEST, "Invalid source");
                     }
                   else
                     message.set_status (Soup.Status.BAD_REQUEST, "Invalid path");
                 }
               else if (subpath == "/refundPay" && method == "POST")
                 {
                   var refund_object = Json.gobject_from_data (typeof (RestApi.RefundRequest), (string) body.data, (ssize_t) body.length);
                   var refund = refund_object as RestApi.RefundRequest;
                   credentials.check_source (refund.request.Source);
                   var result = got_refund_request (credentials, refund.request);
                   if (result != null)
                     {
                       var response = new RestApi.RefundResponse (result);
                       var length = (size_t) 0;
                       var data = Json.gobject_to_data (response, out length);
                       message.set_response (RestApi.CONTENT_TYPE, Soup.MemoryUse.COPY, data.data[0:length]);
                     }
                   else
                     message.set_status (Soup.Status.INTERNAL_SERVER_ERROR, Soup.Status.get_phrase (Soup.Status.INTERNAL_SERVER_ERROR));
                 }
               else if (subpath.has_prefix ("/getStatusRefundOrder/") && method == "GET")
                 {
                   var parts = subpath.split ("/");
                   if (parts.length == 4)
                     {
                       var refundid = parts[2];
                       int64 src;
                       if (int64.try_parse (parts[3], out src))
                         {
                           credentials.check_source (src);
                           var result = got_refund_status_request (credentials, refundid, src);
                           if (result != null)
                             {
                               var response = new RestApi.RefundStatusResponse (result);
                               var length = (size_t) 0;
                               var data = Json.gobject_to_data (response, out length);
                               message.set_response (RestApi.CONTENT_TYPE, Soup.MemoryUse.COPY, data.data[0:length]);
                             }
                           else
                             message.set_status (Soup.Status.NOT_FOUND, "Refund not found");
                         }
                       else
                         message.set_status (Soup.Status.BAD_REQUEST, "Invalid source");
                     }
                   else
                     message.set_status (Soup.Status.BAD_REQUEST, "Invalid path");
                 }
               else
                 message.set_status (Soup.Status.NOT_FOUND, "Endpoint not found");
             }
         }
    }
}
