//
//  ChromeExtension.m
//  ChromeExtensionQuickLookPlugIn
//
//  Created by Michael Gunder on 2/17/12.
//

#import <Cocoa/Cocoa.h>

CFDataRef extensionThumbnailData(CFStringRef extensionFolderPath);
CFStringRef extractExtension(CFURLRef url);
CFStringRef extensionIconPath(CFStringRef extensionFolderPath);

CFStringRef extensionIconPath(CFStringRef extensionFolderPath) {
    NSData *manifestData = [NSData dataWithContentsOfFile:[(__bridge NSString *)extensionFolderPath stringByAppendingString:@"manifest.json"]];
    NSDictionary *manifest = [NSJSONSerialization JSONObjectWithData:manifestData options:NSJSONReadingMutableLeaves error:nil];
    
    NSString *iconFileName = [[manifest objectForKey:@"icons"] valueForKey:@"128"];
    
    if (!iconFileName) {
        iconFileName = [[manifest objectForKey:@"icons"] valueForKey:@"48"];
    }
    
    return (__bridge CFStringRef)[(__bridge NSString *)extensionFolderPath stringByAppendingString:iconFileName];
}

CFDataRef extensionThumbnailData(CFStringRef extensionFolderPath) {
    CFStringRef iconPath = extensionIconPath(extensionFolderPath);
    
    NSImage *extensionIconImage = [[NSImage alloc] initWithContentsOfFile:(__bridge NSString *)iconPath];
    NSImage *chromeExtensionIconImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleWithIdentifier:@"net.projectdot.ChromeExtension"] pathForImageResource:@"chromeextz"]];
    
    [extensionIconImage setSize:NSMakeSize(64, 64)];
    [chromeExtensionIconImage setSize:NSMakeSize(256, 256)];
    
    NSImage *thumbnailImage = [[NSImage alloc] initWithSize:NSMakeSize(256, 256)];
    [thumbnailImage lockFocus];
    [chromeExtensionIconImage compositeToPoint:NSMakePoint(0, 0) operation:NSCompositeSourceOver];
    [extensionIconImage compositeToPoint:NSMakePoint(47, 82) operation:NSCompositeSourceOver];
    [thumbnailImage unlockFocus];
    
    return (__bridge CFDataRef)[thumbnailImage TIFFRepresentation];
}

CFStringRef extractExtension(CFURLRef url) {
    NSString *extensionPath = [(__bridge NSURL *)url path];
    NSString *extensionFileName = [[extensionPath componentsSeparatedByString:@"/"] lastObject];
    extensionFileName = [extensionFileName substringToIndex:[extensionFileName length] - 4];
    
    NSString *extractionPath = [NSTemporaryDirectory() stringByAppendingFormat:@"net.projectdot.ChromeExtensionQuickLookPlugIn/"];
    extractionPath = [[extractionPath stringByAppendingString:extensionFileName] stringByAppendingString:@"/"];
    
    BOOL directory = YES;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:extractionPath isDirectory:&directory] == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:extractionPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSArray *extractionArguments = [NSArray arrayWithObjects:@"-o", extensionPath, @"-d", extractionPath, nil];
    
    NSTask *extractionTask = [[NSTask alloc] init];
    [extractionTask setArguments:extractionArguments];
    [extractionTask setLaunchPath:@"/usr/bin/unzip"];
    [extractionTask launch];
    
    return (__bridge CFStringRef)extractionPath;
}
