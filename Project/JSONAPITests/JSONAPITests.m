//
//  JSONAPITests.m
//  JSONAPITests
//
//  Created by Josh Holtz on 12/23/13.
//  Copyright (c) 2013 Josh Holtz. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "JSONAPI.h"
#import "JSONAPIResourceDescriptor.h"
#import "JSONAPIErrorResource.h"
#import "JSONAPIResourceParser.h"

#import "CommentResource.h"
#import "PeopleResource.h"
#import "ArticleResource.h"

#import "NewsFeedPostResource.h"
#import "UserResource.h"
#import "SocialCommunityResource.h"
#import "MediaResource.h"
#import "WebPageResource.h"

@interface JSONAPITests : XCTestCase

@end

@implementation JSONAPITests

- (void)setUp {
    [super setUp];

    [JSONAPIResourceDescriptor addResource:[CommentResource class]];
    [JSONAPIResourceDescriptor addResource:[PeopleResource class]];
    [JSONAPIResourceDescriptor addResource:[ArticleResource class]];
    [JSONAPIResourceDescriptor addResource:[UserResource class]];
    [JSONAPIResourceDescriptor addResource:[SocialCommunityResource class]];
    [JSONAPIResourceDescriptor addResource:[MediaResource class]];
    [JSONAPIResourceDescriptor addResource:[WebPageResource class]];
    [JSONAPIResourceDescriptor addResource:[NewsFeedPostResource class]];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testMeta {
    NSDictionary *json = [self mainExampleJSON];
    JSONAPI *jsonAPI = [JSONAPI jsonAPIWithDictionary:json];
    
    XCTAssertNotNil(jsonAPI.meta, @"Meta should not be nil");
    XCTAssertEqualObjects(jsonAPI.meta[@"hehe"], @"hoho", @"Meta's 'hehe' should equal 'hoho'");
}

- (void)testDataArticles {
    NSDictionary *json = [self mainExampleJSON];
    JSONAPI *jsonAPI = [JSONAPI jsonAPIWithDictionary:json];
    
    XCTAssertNotNil(jsonAPI.resource, @"Resource should not be nil");
    XCTAssertNotNil(jsonAPI.resources, @"Resources should not be nil");
    XCTAssertEqual(jsonAPI.resources.count, 1, @"Resources should contain 1 resource");
    
    ArticleResource *article = jsonAPI.resource;
    XCTAssert([article isKindOfClass:[ArticleResource class]], @"Article should be a ArticleResource");
    XCTAssertEqualObjects(article.ID, @"1", @"Article id should be 1");
    XCTAssertEqualObjects(article.title, @"JSON API paints my bikeshed!", @"Article title should be 'JSON API paints my bikeshed!'");
	
	NSArray *dateStrings = @[@"2015-09-01T12:15:00Z",@"2015-08-01T06:15:00Z"];
	XCTAssertEqualObjects(article.versions, dateStrings, @"Article versions should contain an array of date strings");
}

- (void)testIncludedPeopleAndComments {
    NSDictionary *json = [self mainExampleJSON];
    JSONAPI *jsonAPI = [JSONAPI jsonAPIWithDictionary:json];
    
    XCTAssertNotNil(jsonAPI.includedResources, @"Included resources should not be nil");
    XCTAssertEqual(jsonAPI.includedResources.count, 2, @"Included resources should contain 2 types");
    
}

- (void)testDataArticleAuthorAndComments {
    NSDictionary *json = [self mainExampleJSON];
    JSONAPI *jsonAPI = [JSONAPI jsonAPIWithDictionary:json];
	
    ArticleResource *article = jsonAPI.resource;
    CommentResource *firstComment = article.comments.firstObject;
    
    XCTAssertNotNil(article.author, @"Article's author should not be nil");
    XCTAssertNotNil(article.comments, @"Article's comments should not be nil");
    XCTAssertEqual(article.comments.count, 2, @"Article should contain 2 comments");
    XCTAssertEqualObjects(article.author.firstName, @"Dan", @"Article's author firstname should be 'Dan'");
    XCTAssertEqualObjects(firstComment.text, @"First!", @"Article's first comment should be 'First!'");
    XCTAssertEqualObjects(firstComment.author.firstName, @"Dan", @"Article's first comment author should be 'Dan'");
}

- (void)testIncludedCommentIsLinked {
    NSDictionary *json = [self mainExampleJSON];
    JSONAPI *jsonAPI = [JSONAPI jsonAPIWithDictionary:json];
    
    CommentResource *comment = [jsonAPI includedResource:@"5" withType:@"comments"];
    XCTAssertNotNil(comment.author, @"Comment's author should not be nil");
    XCTAssertEqualObjects(comment.author.ID, @"9", @"Comment's author's ID should be 2");
}

- (void)testNoError {
    NSDictionary *json = [self mainExampleJSON];
    JSONAPI *jsonAPI = [JSONAPI jsonAPIWithDictionary:json];
 
    XCTAssertFalse([jsonAPI hasErrors], @"JSON API should not have errors");
}

- (void)testError {
    NSDictionary *json = [self errorExampleJSON];
    JSONAPI *jsonAPI = [JSONAPI jsonAPIWithDictionary:json];
    
    XCTAssertTrue([jsonAPI hasErrors], @"JSON API should have errors");
    
    JSONAPIErrorResource *error = jsonAPI.errors.firstObject;
    XCTAssertEqualObjects(error.ID, @"123456", @"Error id should be 123456");
}

- (void)testSerializeSimple {
    PeopleResource *newAuthor = [[PeopleResource alloc] init];
    
    newAuthor.firstName = @"Karl";
    newAuthor.lastName = @"Armstrong";
    
    NSDictionary *json = [JSONAPIResourceParser dictionaryFor:newAuthor];
    XCTAssertEqualObjects(json[@"type"], @"people", @"Did not create person!");
    XCTAssertEqualObjects(json[@"attributes"][@"first-name"], @"Karl", @"Wrong first name!");
    XCTAssertNil(json[@"attributes"][@"twitter"], @"Wrong Twitter!.");
}

- (void)testSerializeWithFormat {
    ArticleResource *newArticle = [[ArticleResource alloc] init];
    newArticle.title = @"Title";
    newArticle.date = [NSDate date];
    
    NSDictionary *json = [JSONAPIResourceParser dictionaryFor:newArticle];
    XCTAssertEqualObjects(json[@"type"], @"articles", @"Did not create article!");
    XCTAssertNotNil(json[@"attributes"][@"date"], @"Wrong date!");
    XCTAssertTrue([json[@"attributes"][@"date"] isKindOfClass:[NSString class]], @"Date should be string!.");
}

- (void)testSerializeComplex {
    PeopleResource *newAuthor = [[PeopleResource alloc] init];
    
    newAuthor.ID = [NSUUID UUID];
    newAuthor.firstName = @"Karl";
    newAuthor.lastName = @"Armstrong";
    
    CommentResource *newComment = [[CommentResource alloc] init];
    newComment.ID = [NSUUID UUID];
    newComment.author = newAuthor;
    newComment.text = @"First!";
    
    ArticleResource *newArticle = [[ArticleResource alloc] init];
    newArticle.title = @"Title";
    newArticle.author = newAuthor;
    newArticle.date = [NSDate date];
    newArticle.comments = [[NSArray alloc] initWithObjects:newComment, nil];
    
    NSDictionary *json = [JSONAPIResourceParser dictionaryFor:newArticle];
    XCTAssertEqualObjects(json[@"type"], @"articles", @"Did not create Article!");
    XCTAssertNotNil(json[@"relationships"], @"Did not create links!");
    XCTAssertNotNil(json[@"relationships"][@"author"], @"Did not create links!");
    XCTAssertNotNil(json[@"relationships"][@"author"][@"data"], @"Did not create links!");
    XCTAssertEqualObjects(json[@"relationships"][@"author"][@"data"][@"id"], newAuthor.ID, @"Wrong link ID!.");
    XCTAssertNil(json[@"relationships"][@"author"][@"first-name"], @"Bad link!");

    XCTAssertNotNil(json[@"relationships"][@"comments"], @"Did not create links!");
    XCTAssertTrue([json[@"relationships"][@"comments"] isKindOfClass:[NSArray class]], @"Comments should be array!.");
    XCTAssertEqual([json[@"relationships"][@"comments"] count], 1, @"Comments should have 1 element!.");
}

- (void)testCreate {
  PeopleResource *newAuthor = [[PeopleResource alloc] init];
  
  newAuthor.firstName = @"Karl";
  newAuthor.lastName = @"Armstrong";
  
  JSONAPI *jsonAPI = [JSONAPI jsonAPIWithResource:newAuthor];
  XCTAssertEqualObjects([jsonAPI dictionary][@"data"][@"type"], @"people", @"Did not create person!");
}

#pragma mark - Generic relationships tests

- (void)testGenericMappingAndParsing {
    NSDictionary *json = [self genericRelationshipsExampleJSON];
    JSONAPI *jsonAPI = [JSONAPI jsonAPIWithDictionary:json];
    
    NSArray <NewsFeedPostResource *> *posts = jsonAPI.resources;
    
    NewsFeedPostResource *firstPost = posts.firstObject;
    UserResource *firstPostAuthor = firstPost.publisher;
    
    NewsFeedPostResource *secondPost = posts.lastObject;
    SocialCommunityResource *secondPostAuthor = secondPost.publisher;
    
    XCTAssertNotNil(firstPostAuthor, @"First post's author should not be nil");
    XCTAssertTrue(firstPostAuthor.class == UserResource.class, @"First post's author should be of class UserResource");
    XCTAssertEqualObjects(firstPostAuthor.name, @"Sam", @"First post's author name should be 'Sam'");
    
    XCTAssertNotNil(secondPostAuthor, @"Second post's author should not be nil");
    XCTAssertTrue(secondPostAuthor.class == SocialCommunityResource.class, @"First post's author should be of class SocialCommunityResource");
    XCTAssertEqualObjects(secondPostAuthor.title, @"Testing Social Community", @"Second post's author title should be 'Testing Social Community'");
    
    XCTAssertNotNil(firstPost.attachments, @"First post's attachments should not be nil");
    XCTAssertEqual(firstPost.attachments.count, 2, @"First post's attachments should contain 2 objects");
    
    XCTAssertTrue(((JSONAPIResourceBase *)firstPost.attachments.firstObject).class == MediaResource.class, @"First attachment should be of class MediaResource");
    XCTAssertEqualObjects(((MediaResource *)firstPost.attachments.firstObject).mimeType, @"image/jpg", @"Media mime type should be 'image/jpg'");
    
    XCTAssertTrue(((JSONAPIResourceBase *)firstPost.attachments.lastObject).class == WebPageResource.class, @"Second attachment should be of class WebPageResource");
    XCTAssertEqualObjects(((WebPageResource *)firstPost.attachments.lastObject).pageUrl, @"http://testingservice.com/content/testPage.html", @"Web page url should be 'http://testingservice.com/content/testPage.html'");
}

- (void)testGenericSerialization {
    NSDictionary *json = [self genericRelationshipsExampleJSON];
    JSONAPI *jsonAPI = [JSONAPI jsonAPIWithDictionary:json];
    
    NSArray <NewsFeedPostResource *> *posts = jsonAPI.resources;
    
    NSDictionary *serializedFirstPost = [JSONAPIResourceParser dictionaryFor:posts.firstObject];
    NSDictionary *serializedSecondPost = [JSONAPIResourceParser dictionaryFor:posts.lastObject];
    
    XCTAssertNotNil(serializedFirstPost[@"relationships"][@"attachments"][0], @"Media attachment should not be nil");
    XCTAssertNotNil(serializedFirstPost[@"relationships"][@"attachments"][1], @"Web page url attachment should not be nil");
    
    XCTAssertEqualObjects(serializedFirstPost[@"relationships"][@"attachments"][0][@"data"][@"id"], @15, @"Media id should be '15'");
    XCTAssertEqualObjects(serializedFirstPost[@"relationships"][@"attachments"][0][@"data"][@"type"], @"Media", @"Media type should be 'Media'");
    
    XCTAssertEqualObjects(serializedFirstPost[@"relationships"][@"publisher"][@"data"][@"id"], @45, @"User id should be '45'");
    XCTAssertEqualObjects(serializedFirstPost[@"relationships"][@"publisher"][@"data"][@"type"], @"User", @"User type should be 'User'");
    
    XCTAssertEqualObjects(serializedSecondPost[@"relationships"][@"publisher"][@"data"][@"id"], @23, @"Social community id should be '23'");
    XCTAssertEqualObjects(serializedSecondPost[@"relationships"][@"publisher"][@"data"][@"type"], @"SocialCommunity", @"SocialCommunity type should be 'SocialCommunity'");
}

#pragma mark - Private

- (NSDictionary*)genericRelationshipsExampleJSON {
    return [self jsonFor:@"generic_relationships_example" ofType:@"json"];
}

- (NSDictionary*)mainExampleJSON {
    return [self jsonFor:@"main_example" ofType:@"json"];
}

- (NSDictionary*)errorExampleJSON {
    return [self jsonFor:@"error_example" ofType:@"json"];
}

- (NSDictionary*)jsonFor:(NSString*)resource ofType:(NSString*)type {
    NSString *path = [[NSBundle mainBundle] pathForResource:resource ofType:type];
    NSString *jsonStr = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    return [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
}

@end
