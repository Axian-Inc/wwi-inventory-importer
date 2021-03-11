using System;
using System.Collections.Generic;
using System.Text.Json;
using Amazon.DynamoDBv2.DocumentModel;
using Amazon.DynamoDBv2.Model;
using Amazon.Runtime;

namespace PurchaseStreamLambda
{
    public static class DynamoHelper
    {
        /// <summary>
        /// Maps a POCO to an attribute map dictionary in order to save to Dynamo.
        /// </summary>
        /// <param name="obj"></param>
        /// <typeparam name="T"></typeparam>
        /// <returns></returns>
        public static Dictionary<string, AttributeValue> ToAttributeMap<T>(this T obj)
        {
            if (obj == null)
                throw new ArgumentNullException(nameof(obj));

            var jsonOpts = new JsonSerializerOptions()
            {
                IgnoreNullValues = true
            };

            // The built in serializer has an issue with handling derived types, unless you explicity pass in the type information:
            // https://stackoverflow.com/questions/59258655/system-text-json-jsonserializer-doesnt-serialize-properties-from-derived-classe/59536948#59536948
            var json = JsonSerializer.Serialize(obj, obj.GetType(), jsonOpts);
            return json.ToAttributeMap();
        }

        /// <summary>
        /// Maps a POCO to an attribute map dictionary in order to save to Dynamo.
        /// </summary>
        /// <param name="obj"></param>
        /// <typeparam name="T"></typeparam>
        /// <returns></returns>
        public static Dictionary<string, AttributeValue> ToAttributeMap(this string jsonString)
        {
            return Document.FromJson(jsonString).ToAttributeMap();
        }

        /// <summary>
        /// Attempts to parse a string as a dynamo Document. If the string is not json, null or empty, false is returned.
        /// </summary>
        /// <param name="jsonString"></param>
        /// <param name="doc"></param>
        /// <returns></returns>
        public static bool TryParseAsDocument(this string jsonString, out Document doc)
        {
            try
            {
                doc = Document.FromJson(jsonString);
                return true;
            }
            catch
            {
                doc = null;
                return false;
            }
        }

        /// <summary>
        /// Maps Dynamo attribute value dictionary to a POCO.
        /// </summary>
        /// <param name="attibuteValues"></param>
        /// <typeparam name="T"></typeparam>
        /// <returns></returns>
        /// <remarks></remarks>
        public static T ToDynamoEntity<T>(this Dictionary<string, AttributeValue> attibuteValues)
        {
            var document = Document.FromAttributeMap(attibuteValues);
            var json = document.ToJson();

            return JsonSerializer.Deserialize<T>(json);
        }
        
        public static Dictionary<string, string> ToDictionary(this ResponseMetadata metadata)
        {
            if (metadata == null)
                return new Dictionary<string, string>();

            return new Dictionary<string, string>(metadata.Metadata)
            {
                {nameof(metadata.RequestId), metadata.RequestId}
            };
        }
    }
}

