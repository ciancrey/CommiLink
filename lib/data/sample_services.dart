import '../models/service.dart';

/// Sample listings for the demo. We will replace this with real stored
/// data when we build "Post a service".
const List<Service> sampleServices = [
  Service(
    id: 's1',
    freelancerName: 'Ana Dela Cruz',
    role: 'Video Editor & Motion Designer',
    title: 'I will edit your YouTube video (up to 10 minutes)',
    description:
    'Cuts, transitions, background music, color correction and subtitles.',
    category: 'Video',
    price: 1800,
    deliveryDays: 4,
    rating: 4.9,
  ),
  Service(
    id: 's2',
    freelancerName: 'Maria Santos',
    role: 'Graphic Designer',
    title: 'Clean, modern logo for your brand',
    description:
    'Three logo concepts, two revisions, and final files ready to use.',
    category: 'Design',
    price: 1500,
    deliveryDays: 5,
    rating: 4.8,
  ),
  Service(
    id: 's3',
    freelancerName: 'Josh Reyes',
    role: 'Mobile & Web Developer',
    title: 'I will build your landing page',
    description:
    'Responsive, fast landing page with contact form and basic SEO.',
    category: 'Programming',
    price: 3500,
    deliveryDays: 7,
    rating: 4.7,
  ),
  Service(
    id: 's4',
    freelancerName: 'Kim Navarro',
    role: 'Content Writer',
    title: 'SEO blog articles (up to 1,000 words)',
    description:
    'Researched, original articles with headings, keywords and a meta description.',
    category: 'Writing',
    price: 800,
    deliveryDays: 3,
    rating: 4.6,
  ),
  Service(
    id: 's5',
    freelancerName: 'Maria Santos',
    role: 'Graphic Designer',
    title: 'Social media post pack (10 designs)',
    description:
    'Consistent, on-brand posts sized for Facebook and Instagram.',
    category: 'Design',
    price: 2200,
    deliveryDays: 6,
    rating: 4.8,
  ),
  Service(
    id: 's6',
    freelancerName: 'Josh Reyes',
    role: 'Mobile & Web Developer',
    title: 'Fix bugs in your Flutter app',
    description:
    'Debugging, cleanup and short written notes on what was changed.',
    category: 'Programming',
    price: 1200,
    deliveryDays: 2,
    rating: 4.7,
  ),
];