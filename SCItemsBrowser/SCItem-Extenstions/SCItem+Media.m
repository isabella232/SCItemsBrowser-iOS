#import "SCItem+Media.h"

static NSString* const MEDIA_ROOT = @"/sitecore/media library";

@implementation SCItem (Media)

-(BOOL)isMediaImage
{
    if ( ![ self isMediaItem ] )
    {
        return NO;
    }
    
    NSString* itemTemplate = self.itemTemplate;
    
    BOOL isUnversionedImage = [ itemTemplate isEqualToString: @"System/Media/Unversioned/Image" ];
    BOOL isJpegImage        = [ itemTemplate isEqualToString: @"System/Media/Unversioned/Jpeg"  ];
    
    return isUnversionedImage || isJpegImage;
}

-(BOOL)isMediaItem
{
    BOOL result = ( [ self.path hasPrefix: MEDIA_ROOT ] );
    return result;
}

-(NSString*)mediaPath
{
    if ( ! [ self isMediaItem ] )
    {
        return nil;
    }
    
    NSString* mediaPath = [ self.path substringFromIndex: [ MEDIA_ROOT length ] ];
    return mediaPath;
}

-(SCExtendedAsyncOp)mediaLoaderWithOptions:( SCFieldImageParams* )options
{
    if ( [ self isMediaItem ] )
    {
        NSString* mediaPath = [ self mediaPath ];
        
        return [ self.apiContext imageLoaderForSCMediaPath: mediaPath
                                               imageParams: options ];
        
    }
    else
    {
        return nil;
    }
}

@end