/*
 * Copyright (C) 2017  Jonathan Neuschäfer <j.neuschaefer@gmx.net>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 2.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program, in the file LICENSE.GPLv2.
 */
#import <ObjFW/ObjFW.h>

#define ATOM_NS @"http://www.w3.org/2005/Atom"

@interface GitwebScraper: OFObject<OFApplicationDelegate>
{
	OFURL *_URL;
	OFString *_repo;
}
@end

OF_APPLICATION_DELEGATE(GitwebScraper)

@implementation GitwebScraper
- (void)applicationDidFinishLaunching
{
	OFArray *args = [OFApplication arguments];
	if ([args count] != 2) {
		[of_stderr writeFormat: @"Usage: %@ <gitweb base URL>"
					@" <repo-name.git>\n",
			[OFApplication programName]];
		[OFApplication terminateWithStatus: 1];
	}

	_URL = [OFURL URLWithString: [args objectAtIndex: 0]];
	_repo = [args objectAtIndex: 1];

	OFMutableURL *feedURL = [_URL copy];
	[feedURL setQuery: [OFString stringWithFormat: @"p=%@;a=atom", _repo]];
	of_log(@"Downloading feed from %@", feedURL);

	OFString *atom = [OFString stringWithContentsOfURL: feedURL];
	OFXMLElement *XML = [OFXMLElement elementWithXMLString: atom];

	OFArray *commits = [self extractCommits: XML];
	of_log(@"got %u commits", [commits count]);

	OFString *destination = [_repo stringByDeletingPathExtension];
	destination = [destination stringByAppendingString: @".patches"];
	OFFileManager *FM = [OFFileManager defaultManager];
	[FM createDirectoryAtPath: destination
		    createParents: true];
	of_log(@"Saving patches in %@", destination);

	int i = 0;
	for (OFString *commit in commits) {
		OFData *patch = [self patchForCommit: commit];
		OFString *path = [OFString stringWithFormat: @"%08u-%@",
			i++, commit];
		path = [destination stringByAppendingPathComponent: path];
		OFFile *file = [OFFile fileWithPath: path
					       mode: @"wb"];

		[file writeData: patch];
		[file close];
	}


	[OFApplication terminate];
}

bool stringIsHex(OFString *string)
{
	const char *str = [string UTF8String];
	for (size_t i = 0; i < [string UTF8StringLength]; i++)
		if (!((str[i] >= '0' && str[i] <= '9') ||
		      (str[i] >= 'a' && str[i] <= 'f') ||
		      (str[i] >= 'A' && str[i] <= 'F')))
			return false;
	return true;
}

- (OFArray *)extractCommits: (OFXMLElement *)feed
{
	OFMutableArray *commits = [OFMutableArray new];

	for (OFXMLElement *entry in [feed elementsForName: @"entry"
						namespace: ATOM_NS]) {
		OFXMLElement *idElem = [entry elementForName: @"id"
						   namespace: ATOM_NS];
		OF_ENSURE([[[idElem children] firstObject] class]
			  == [OFXMLCharacters class]);

		OFString *str = [[[idElem children] firstObject] description];
		OFURL *URL = [OFURL URLWithString: str];
		OFString *query = [URL query];

		/* Find the h= parameter, which specifies the commit hash. */
		of_range_t r = [query rangeOfString: @";h="
				options: OF_STRING_SEARCH_BACKWARDS];
		OF_ENSURE(r.location != OF_NOT_FOUND);

		r.location += r.length;	/* after the ;h= */
		r.length = 40;		/* the length of a SHA1 hash */

		OFString *commit = [query substringWithRange: r];
		OF_ENSURE(stringIsHex(commit));

		[commits addObject: commit];
	}

	/* Gitweb lists commits in reverse-chronological order. Turn them
	 * around. */
	[commits reverse];

	[commits makeImmutable];
	return commits;
}

- (OFData *)patchForCommit: (OFString *)commit
{
	/*
	 * Example URL:
	 * http://example.org/gitweb/?p=repo.git;a=patch;h=da39a3ee5e6b4b0d3255bfef95601890afd80709
	 */

	OFMutableURL *URL = [_URL copy];
	[URL setQuery: [OFString stringWithFormat:
		@"p=%@;a=patch;h=%@", _repo, commit]];

	of_log(@"Downloading patch from %@", [URL string]);
	return [OFData dataWithContentsOfURL: URL];
}
@end
