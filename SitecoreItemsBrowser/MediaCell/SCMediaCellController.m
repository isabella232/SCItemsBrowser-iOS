#import "SCMediaCellController.h"

#import "SCMediaCellEvents.h"

@implementation SCMediaCellController
{
    SCItem                 * _item                ;
    SCCancelAsyncOperation   _cancelImageLoader   ;
    SCDownloadMediaOptions     * _imageResizingOptions;
}

-(void)dealloc
{
    [ self setModel: nil ];
}

-(void)setModel:( SCItem* )item
{
    if ( nil != self->_cancelImageLoader )
    {
        self->_cancelImageLoader( YES );
    }
    self->_cancelImageLoader = nil;
    self->_item = item;
}

-(void)reloadData
{
    __weak SCMediaCellController* weakSelf = self;
    
    NSParameterAssert( [ self->_item isMediaImage ] );
    
    SCItem* mediaItem = self->_item;
    
    SCDownloadMediaOptions* resizingOptions = [ self normalizedImageResizingOptions ];
    SCExtendedAsyncOp imageLoader = [ self->_item downloadMediaExtendedOperationWithOptions: resizingOptions ];
    SCDidFinishAsyncOperationHandler onImageLoadedBlock = ^void( UIImage* loadedImage, NSError* imageError )
    {
        if ( nil == loadedImage )
        {
            NSParameterAssert( nil != imageError );
            [ weakSelf.delegate mediaCellController: weakSelf
                         didFailLoadingImageForItem: mediaItem
                                          withError: imageError ];
        }
        else
        {
            NSParameterAssert( nil != loadedImage );
            [ weakSelf.delegate mediaCellController: weakSelf
                              didFinishLoadingImage: loadedImage
                                            forItem: mediaItem ];
        }
    };
    
    
    [ self startLoading   ];
    self->_cancelImageLoader = imageLoader( nil, nil, onImageLoadedBlock );
    self->_cancelImageLoader = [ self->_cancelImageLoader copy ];
}

-(SCDownloadMediaOptions*)normalizedImageResizingOptions
{
    SCDownloadMediaOptions* result = self->_imageResizingOptions;
    if ( nil == result )
    {
        result = [ SCDownloadMediaOptions new ];
    }
    
    SCItemSourcePOD* itemSource = self->_item.recordItemSource;
    {
        result.database = itemSource.database;
        result.language = itemSource.language;
    }
    
    return result;
}

-(void)startLoading
{
    [ self->_delegate didStartLoadingImageInMediaCellController: self ];
}


@end
