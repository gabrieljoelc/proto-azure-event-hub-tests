/****** Object:  Table [dbo].[EhTests]    Script Date: 3/16/2020 5:19:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EhTests](
	[TestRun] [int] NULL,
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[PartitionKey] [varchar](100) NULL,
	[PartitionKeyPrefix] [varchar](50) NULL,
	[PartitionKeySuffix] [varchar](50) NULL,
	[CreatedAt] [datetime] NULL,
	[EnqueuedTimeUtc] [datetime] NULL,
	[EnqueuedCounter] [int] NULL,
	[Body] [varchar](100) NULL,
 CONSTRAINT [PK_EhTests] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
