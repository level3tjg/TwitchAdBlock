#import "NSData+TwitchAdBlock.h"

@implementation NSData (TwitchAdBlock)
- (NSData *)twab_requestDataForRequest:(NSURLRequest *)request {
  if (!request) return self;
  NSData *modifiedData;
  if ([request.URL.host isEqualToString:@"gql.twitch.tv"] &&
      [request.URL.path isEqualToString:@"/gql"]) {
    NSError *error;
    id json = [NSJSONSerialization JSONObjectWithData:self
                                              options:NSJSONReadingMutableContainers
                                                error:&error];
    if (!json || error) return self;
    if ([json isKindOfClass:NSMutableDictionary.class]) {
      NSMutableDictionary *jsonDictionary = json;
      NSString *platform = [NSUUID UUID].UUIDString;
      if ([jsonDictionary[@"operationName"] isEqualToString:@"StreamAccessToken"] ||
          [jsonDictionary[@"query"] containsString:@"StreamAccessToken"] ||
          [jsonDictionary[@"operationName"] isEqualToString:@"VodAccessToken"])
        jsonDictionary[@"variables"][@"params"][@"platform"] = platform;
      else if ([jsonDictionary[@"operationName"] isEqualToString:@"ClipAccessToken"])
        jsonDictionary[@"variables"][@"tokenParams"][@"platform"] = platform;
    }
    modifiedData = [NSJSONSerialization dataWithJSONObject:json options:0 error:&error];
    if (error) return self;
  }
  return modifiedData ?: self;
}
- (NSData *)twab_responseDataForRequest:(NSURLRequest *)request {
  if (!request) return self;
  NSData *modifiedData;
  if ([request.URL.host isEqualToString:@"gql.twitch.tv"] &&
      [request.URL.path isEqualToString:@"/gql"]) {
    NSError *error;
    id json = [NSJSONSerialization JSONObjectWithData:self
                                              options:NSJSONReadingMutableContainers
                                                error:&error];
    if (!json || error) return self;
    if ([json isKindOfClass:NSMutableArray.class]) {
      NSMutableArray *jsonArray = json;
      for (NSMutableDictionary *operation in jsonArray) {
        NSMutableDictionary *feedItems = operation[@"data"][@"feedItems"];
        if (feedItems)
          feedItems[@"edges"] = [feedItems[@"edges"]
              filteredArrayUsingPredicate:[NSPredicate
                                              predicateWithFormat:@"node.__typename != 'FeedAd'"]];
      }
    }
    modifiedData = [NSJSONSerialization dataWithJSONObject:json options:0 error:&error];
    if (error) return self;
  }
  return modifiedData ?: self;
}
@end