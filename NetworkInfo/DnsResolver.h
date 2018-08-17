//
//  DnsResolver.h
//  NetworkInfo
//
//  Created by Wu Xiaohua on 8/16/18.
//  Copyright © 2018 Wu Xiaohua. All rights reserved.
//

#ifndef DnsResolver_h
#define DnsResolver_h

#import <Foundation/Foundation.h>

@interface DnsResolver:NSObject
/* Method definition */
- (NSString *) getDNSAddressesStr;
@end

#endif /* DnsResolver_h */
