//
//  DnsResolver.m
//  NetworkInfo
//
//  Created by Wu Xiaohua on 8/16/18.
//  Copyright © 2018 Wu Xiaohua. All rights reserved.
//

#include <arpa/inet.h>
#include <ifaddrs.h>
#include <resolv.h>
#include <dns.h>
#include "DnsResolver.h"

@implementation DnsResolver

- (NSString *) getDNSAddressesStr
{
    NSMutableString *addressStr = [[NSMutableString alloc]initWithString:@"DNS Addresses \n"];
    
    res_state res = malloc(sizeof(struct __res_state));
    
    int result = res_ninit(res);
    
    if ( result == 0 )
    {
        for ( int i = 0; i < res->nscount; i++ )
        {
            NSString *s = [NSString stringWithUTF8String :  inet_ntoa(res->nsaddr_list[i].sin_addr)];
            [addressStr appendFormat:@"%@\n",s];
            NSLog(@"%@",s);
        }
    }
    else
        [addressStr appendString:@" res_init result != 0"];
    
    free(res);
    
    return addressStr;
}

@end
