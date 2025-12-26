// lib/src/utils/nlp/config_keys.dart

// Small, focused constants for NLP utilities.
const Set<String> singularNounExceptions = {
  'status',
  'access',
  'process',
  'class',
  'address',
  'canvas',
  'focus',
  'loss',
  'glass',
  'pass',
  'progress',
  'analysis',
  'diagnosis',
};

const Set<String> commonNouns = {
  'email',
  'profile',
  'data',
  'user',
  'state',
  'event',
  'auth',
  'dto',
  'request',
  'response',
  'id',
  'text',
  'date',
  'image',
  'list',
  'login',
  'logout',
  'map',
  'type',
  'info',
  'detail',
  'item',
  'violation',
  'port',
};

const Map<String, String> irregularPlurals = {
  'children': 'child',
  'men': 'man',
  'women': 'woman',
  'people': 'person',
  'feet': 'foot',
  'teeth': 'tooth',
  'mice': 'mouse',
  'geese': 'goose',
  'data': 'datum',
};

const Set<String> commonVerbs = {
  'get',
  'set',
  'fetch',
  'send',
  'save',
  'delete',
  'update',
  'load',
  'login',
  'logout',
  'create',
  'read',
  'write',
  'remove',
  'add',
};

const Set<String> commonAdverbs = {
  'very',
  'quickly',
  'slowly',
  'recently',
  'already',
  'always',
  'never',
  'often',
  'usually',
  'sometimes',
  'rather',
  'barely',
  'hardly',
  'mostly',
  'simply',
};

const Set<String> pronouns = {
  'i',
  'you',
  'he',
  'she',
  'it',
  'we',
  'they',
  'me',
  'him',
  'her',
  'us',
  'them',
  'my',
  'your',
  'his',
  'its',
  'our',
  'their',
  'mine',
  'yours',
  'hers',
  'ours',
  'theirs',
};

const Set<String> commonPrepositions = {
  'about', 'above', 'across', 'after', 'against', 'along', 'among', 'around', 'at',
  'before', 'behind', 'below', 'beneath', 'beside', 'between', 'beyond', 'by',
  'down', 'during', 'except', 'for', 'from', 'in', 'inside', 'into', 'like',
  'near', 'of', 'off', 'on', 'out', 'outside', 'over', 'past', 'since',
  'through', 'throughout', 'to', 'toward', 'under', 'underneath', 'until', 'up',
  'upon', 'with', 'within', 'without', 'via'
};

/// Common conjunctions.
const Set<String> commonConjunctions = {
  'and', 'but', 'for', 'nor', 'or', 'so', 'yet',
  'after', 'although', 'as', 'because', 'before', 'if', 'once', 'since',
  'than', 'that', 'though', 'till', 'unless', 'until', 'when', 'whenever',
  'where', 'whereas', 'wherever', 'while'
};

/// Common determiners.
const Set<String> determiners = {
  'the',
  'a',
  'an',
  'this',
  'that',
  'these',
  'those',
  'my',
  'your',
  'his',
  'her',
  'its',
  'our',
  'their',
  'some',
  'any',
  'each',
  'every',
};

/// Common irregular past tense verbs.
const Map<String, String> irregularPastVerbs = {
  'ate': 'eat',
  'became': 'become',
  'began': 'begin',
  'built': 'build',
  'came': 'come',
  'did': 'do',
  'found': 'find',
  'gave': 'give',
  'had': 'have',
  'knew': 'know',
  'left': 'leave',
  'put': 'put',
  'ran': 'run',
  'said': 'say',
  'saw': 'see',
  'sent': 'send',
  'showed': 'show',
  'thought': 'think',
  'took': 'take',
  'was': 'be',
  'were': 'be',
  'went': 'go',
  'wrote': 'write',
};
